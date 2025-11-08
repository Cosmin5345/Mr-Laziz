namespace TaskBoardApi.Models;

public record RegisterRequest(string Username, string Password);
public record LoginRequest(string Username, string Password);
public record CreateTaskRequest(string Title, string? Description);
public record UpdateStatusRequest(string NewStatus);
public record AssignTaskRequest(int? UserId);
public record UpdateTaskRequest(string Title, string? Description);