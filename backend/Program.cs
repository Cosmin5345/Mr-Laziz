using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using System.Security.Claims;
using TaskBoardApi.Data;
using TaskBoardApi.Models;
using TaskBoardApi.Services;

var builder = WebApplication.CreateBuilder(args);

// Configure SQLite
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite("Data Source=tasks.db"));

// Configure JWT
var jwtKey = "YourSuperSecretKeyForJWTTokenGeneration12345"; // In production, use configuration
var key = Encoding.ASCII.GetBytes(jwtKey);

builder.Services.AddAuthentication(x =>
{
    x.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    x.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(x =>
{
    x.RequireHttpsMetadata = false;
    x.SaveToken = true;
    x.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = false,
        ValidateAudience = false
    };
});

builder.Services.AddAuthorization();

// Configure CORS for development
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Register services
builder.Services.AddSingleton<JwtService>(new JwtService(jwtKey));
builder.Services.AddSingleton<PasswordService>();

var app = builder.Build();

// Ensure database is created
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.EnsureCreated();
}

app.UseCors();
app.UseAuthentication();
app.UseAuthorization();

// ============================================
// AUTHENTICATION ENDPOINTS (No Auth Required)
// ============================================

app.MapPost("/auth/register", async (RegisterRequest request, AppDbContext db, PasswordService passwordService) =>
{
    if (await db.Users.AnyAsync(u => u.Username == request.Username))
    {
        return Results.BadRequest(new { message = "Username already exists" });
    }

    var user = new User
    {
        Username = request.Username,
        PasswordHash = passwordService.HashPassword(request.Password)
    };

    db.Users.Add(user);
    await db.SaveChangesAsync();

    return Results.Created($"/users/{user.Id}", new { id = user.Id, username = user.Username });
});

app.MapPost("/auth/login", async (LoginRequest request, AppDbContext db, PasswordService passwordService, JwtService jwtService) =>
{
    var user = await db.Users.FirstOrDefaultAsync(u => u.Username == request.Username);
    
    if (user == null || !passwordService.VerifyPassword(request.Password, user.PasswordHash))
    {
        return Results.Unauthorized();
    }

    var token = jwtService.GenerateToken(user.Id, user.Username);
    
    return Results.Ok(new { token });
});

// ============================================
// USER ENDPOINTS (Auth Required)
// ============================================

app.MapGet("/users", async (AppDbContext db) =>
{
    var users = await db.Users
        .Select(u => new { id = u.Id, username = u.Username })
        .ToListAsync();
    
    return Results.Ok(users);
}).RequireAuthorization();

// ============================================
// TASK MANAGEMENT ENDPOINTS (Auth Required)
// ============================================

app.MapGet("/tasks", async (AppDbContext db) =>
{
    var tasks = await db.TaskItems
        .Include(t => t.CreatedByUser)
        .Include(t => t.AssignedToUser)
        .Select(t => new
        {
            id = t.Id,
            title = t.Title,
            description = t.Description,
            status = t.Status,
            createdByUserId = t.CreatedByUserId,
            createdByUsername = t.CreatedByUser != null ? t.CreatedByUser.Username : null,
            assignedToUserId = t.AssignedToUserId,
            assignedToUsername = t.AssignedToUser != null ? t.AssignedToUser.Username : null
        })
        .ToListAsync();
    
    return Results.Ok(tasks);
}).RequireAuthorization();

app.MapPost("/tasks", async (CreateTaskRequest request, HttpContext httpContext, AppDbContext db) =>
{
    var userIdClaim = httpContext.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (userIdClaim == null || !int.TryParse(userIdClaim, out int userId))
    {
        return Results.Unauthorized();
    }

    var task = new TaskItem
    {
        Title = request.Title,
        Description = request.Description,
        Status = "Todo",
        CreatedByUserId = userId
    };

    db.TaskItems.Add(task);
    await db.SaveChangesAsync();

    return Results.Created($"/tasks/{task.Id}", new
    {
        id = task.Id,
        title = task.Title,
        description = task.Description,
        status = task.Status,
        createdByUserId = task.CreatedByUserId
    });
}).RequireAuthorization();

app.MapPut("/tasks/{id}/status", async (int id, UpdateStatusRequest request, AppDbContext db) =>
{
    var task = await db.TaskItems.FindAsync(id);
    if (task == null)
    {
        return Results.NotFound();
    }

    var validStatuses = new[] { "Todo", "InProgress", "Done" };
    if (!validStatuses.Contains(request.NewStatus))
    {
        return Results.BadRequest(new { message = "Invalid status. Must be: Todo, InProgress, or Done" });
    }

    task.Status = request.NewStatus;
    await db.SaveChangesAsync();

    return Results.Ok(new { id = task.Id, status = task.Status });
}).RequireAuthorization();

app.MapPut("/tasks/{id}/assign", async (int id, AssignTaskRequest request, AppDbContext db) =>
{
    var task = await db.TaskItems.FindAsync(id);
    if (task == null)
    {
        return Results.NotFound();
    }

    if (request.UserId.HasValue)
    {
        var userExists = await db.Users.AnyAsync(u => u.Id == request.UserId.Value);
        if (!userExists)
        {
            return Results.BadRequest(new { message = "User not found" });
        }
    }

    task.AssignedToUserId = request.UserId;
    await db.SaveChangesAsync();

    return Results.Ok(new { id = task.Id, assignedToUserId = task.AssignedToUserId });
}).RequireAuthorization();

app.MapPut("/tasks/{id}", async (int id, UpdateTaskRequest request, AppDbContext db) =>
{
    var task = await db.TaskItems.FindAsync(id);
    if (task == null)
    {
        return Results.NotFound();
    }

    task.Title = request.Title;
    task.Description = request.Description;
    await db.SaveChangesAsync();

    return Results.Ok(new
    {
        id = task.Id,
        title = task.Title,
        description = task.Description,
        status = task.Status
    });
}).RequireAuthorization();

app.Run();