using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Models;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers;

public class ChatController : Controller
{
    private readonly ChatService _chatService;

    public ChatController(ChatService chatService)
    {
        _chatService = chatService;
    }

    [HttpGet]
    public IActionResult Index()
    {
        return View(new ChatViewModel());
    }

    [HttpPost]
    public async Task<IActionResult> Index(ChatViewModel model)
    {
        if (!string.IsNullOrWhiteSpace(model.Prompt))
        {
            model.Response = await _chatService.SendAsync(model.Prompt);
        }
        return View(model);
    }
}
