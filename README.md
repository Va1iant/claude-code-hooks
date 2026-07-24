# Claude Code - Windows Notification Hooks

Smart taskbar-flash and toast notifications for [Claude Code](https://claude.com/claude-code) on Windows. Get told when an agent finishes, needs approval, or completes a long-running tool - in both **VSCode** (native panel + integrated terminal) and **standalone terminals**.

## Why

Running long or parallel Claude Code sessions, it is easy to miss when one stops and waits for you. These hooks flash the taskbar of the *right* window (not every window sharing the project name) and raise a toast for slow tools, so you can leave a session running and get pulled back exactly when needed.

## What it does

- **Task finished / waiting for input** - taskbar blinks if the window is not focused (`Stop` hook).
- **Waiting for approval** - taskbar blinks after ~5s if a tool call is still pending (`PreToolUse` hook).
- **Long tool done** - toast notification if a tool took >15s and the window is not focused (`PostToolUse` hook).
- **Per-session window targeting** - each session is bound to its own host window at start, so with many agents running only the relevant window blinks. Falls back to folder-name matching if the binding is missing.

## Contents

| File | Role |
|------|------|
| `flash_smart.ps1` | Main entry - resolves the session's window and flashes it |
| `flash_taskbar.ps1` | Low-level taskbar flash |
| `stop_notify.ps1` | `Stop` hook - fires when the agent stops |
| `pre_tool_notify.ps1` | `PreToolUse` hook - approval-pending flash |
| `post_tool_notify.ps1` | `PostToolUse` hook - long-tool toast |
| `ClaudeWinHelper.cs` / `claude-win-helper.exe` | Small C# helper for native Win32 window flashing |

## Setup

Drop the scripts into `~/.claude/hooks/` and wire them up in `~/.claude/settings.json` under the `Stop`, `PreToolUse` and `PostToolUse` hook events. Point each event at the matching script above.
