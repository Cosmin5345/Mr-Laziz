namespace TaskBoardApi.Models;

public class TaskItem
{
    public int Id { get; set; }
    public required string Title { get; set; }
    public string? Description { get; set; }
    public string Status { get; set; } = "Todo";
    public int CreatedByUserId { get; set; }
    public int? AssignedToUserId { get; set; }
    
    // Navigation properties
    public User? CreatedByUser { get; set; }
    public User? AssignedToUser { get; set; }
}