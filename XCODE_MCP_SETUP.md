# Xcode MCP Setup & Troubleshooting

This document covers how to set up and troubleshoot the Xcode Model Context Protocol (MCP) integration with external AI coding tools like Opencode, Claude Code, Cursor, and Codex.

## What is Xcode MCP?

Xcode 16.3 RC (and later) includes a built-in MCP server that exposes 20 native tools to external AI agents. This allows AI assistants to:
- Read/write project files using Xcode's project structure
- Build projects and get structured error messages
- Run tests and get results
- Render SwiftUI previews as images
- Search Apple documentation and WWDC transcripts
- Access live diagnostics and compiler errors

The connection is made via `xcrun mcpbridge`, which bridges MCP protocol requests to Xcode's internal services.

## Prerequisites

1. **Xcode 16.3 RC or later** installed
2. **Xcode project open** - MCP requires an active Xcode project/workspace
3. **External AI tool** that supports MCP (Opencode, Claude Code, Cursor, Codex, etc.)

## Setup for Opencode

### 1. Enable MCP in Xcode

**CRITICAL STEP:** Before any external tool can connect:

1. Open **Xcode** (ensure a project is open)
2. Go to **Xcode → Settings** (⌘,)
3. Select the **Intelligence** tab
4. Under **Model Context Protocol**, toggle **"Enable Xcode Tools"** ON

### 2. Configure Opencode

Add to `~/.config/opencode/opencode.json` in the `mcp` section:

```json
"xcode": {
  "type": "local",
  "command": [
    "xcrun",
    "mcpbridge"
  ],
  "enabled": true,
  "timeout": 30000
}
```

**Note:** 30-second timeout gives Xcode enough time to respond on first connection.

### 3. Verify Configuration

```bash
opencode mcp list
```

You should see:
```
●  ✓ xcode [connected]
     xcrun mcpbridge
```

## Setup for Other Tools

### Claude Code

```bash
claude mcp add --transport stdio xcode -- xcrun mcpbridge
```

Verify: `claude mcp list`

### Codex

```bash
codex mcp add xcode -- xcrun mcpbridge
```

Verify: `codex mcp list`

### Cursor

Add to `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "xcode-tools": {
      "command": "xcrun",
      "args": ["mcpbridge"]
    }
  }
}
```

**Note:** Cursor may require a wrapper script to handle schema compliance. See [this article](https://rudrank.com/exploring-xcode-using-mcp-tools-cursor-external-clients) for details.

## Troubleshooting

### Issue: "Failed to get tools" or Connection Fails

**Symptoms:**
```
●  ✗ xcode [failed]
     Failed to get tools
     xcrun mcpbridge
```

**Solution:** 
The most common cause is **forgetting to allow Xcode permission**.

1. **Switch to Xcode window** - bring Xcode to the foreground
2. Look for a permission dialog that says:
   > "Do you want to allow [tool name] to access Xcode?"
3. Click **"Allow"**
4. Restart your AI tool or reconnect

**Why this happens:**
- On first connection, `mcpbridge` produces NO output until permission is granted
- The permission dialog may appear behind other windows
- Until you click "Allow", `mcpbridge` silently fails

### Issue: Xcode Not Running

**Symptoms:**
- `mcpbridge` exits immediately with no output
- Error about "no Xcode processes found"

**Solution:**
1. Open Xcode
2. Open a project (MCP requires an active workspace)
3. Wait for indexing to complete
4. Try connecting again

### Issue: Multiple Xcode Versions

**Symptoms:**
- Connection fails despite Xcode being open
- `mcpbridge` connects to wrong Xcode

**Solution:**
Explicitly set the Xcode PID in your MCP config:

```json
"xcode": {
  "type": "local",
  "command": ["xcrun", "mcpbridge"],
  "env": {
    "MCP_XCODE_PID": "12345"
  },
  "enabled": true,
  "timeout": 30000
}
```

Get the PID:
```bash
pgrep -x Xcode
```

### Issue: Connection Works But Tools Don't Execute

**Symptoms:**
- MCP shows "connected"
- Tool calls fail or timeout

**Solution:**
1. Check that you have a **tabIdentifier** - most tools need one
2. Ensure the **project is indexed** in Xcode
3. Verify the **scheme is valid** and can build
4. Check Xcode for any **build or configuration errors**

### Issue: Timeout Errors

**Symptoms:**
- "Connection timeout" or "Tool execution timeout"

**Solution:**
Increase timeout in config:
```json
"timeout": 60000  // 60 seconds instead of 10
```

First connections and large projects may take longer.

## Available Xcode MCP Tools

Once connected, you get access to 20 tools:

**File Operations:**
- `XcodeRead` - Read files
- `XcodeWrite` - Write files  
- `XcodeUpdate` - Edit files with patches
- `XcodeGlob` - Find files by pattern
- `XcodeGrep` - Search file contents
- `XcodeLS` - List directories
- `XcodeMakeDir` - Create directories
- `XcodeRM` - Remove files
- `XcodeMV` - Move/rename files

**Build & Test:**
- `BuildProject` - Build the project
- `GetBuildLog` - Get build output with errors
- `RunAllTests` - Run all tests
- `RunSomeTests` - Run specific tests
- `GetTestList` - List available tests

**Diagnostics:**
- `XcodeListNavigatorIssues` - Get all Xcode issues
- `XcodeRefreshCodeIssuesInFile` - Get live file diagnostics

**Advanced:**
- `ExecuteSnippet` - Run Swift code snippets
- `RenderPreview` - Render SwiftUI previews as images
- `DocumentationSearch` - Search Apple docs & WWDC
- `XcodeListWindows` - List open Xcode windows/tabs

## Security Considerations

- MCP server only accepts **local connections** (not exposed to network)
- You must **explicitly grant permission** for each tool
- External processes can **trigger builds and run code** on your machine
- Permission dialog shows the **exact binary path and PID** of the requesting tool

## Additional Resources

- [Apple: Giving external agentic coding tools access to Xcode](https://developer.apple.com/documentation/xcode/giving-agentic-coding-tools-access-to-xcode)
- [BleepingSwift: How to Use Xcode's MCP Server](https://bleepingswift.com/blog/xcode-mcp-server-ai-workflow)
- [Rudrank Riyam: Using Xcode MCP Tools in Cursor and Claude Code](https://rudrank.com/exploring-xcode-using-mcp-tools-cursor-external-clients)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)

## Quick Reference

**Check if mcpbridge exists:**
```bash
xcrun --find mcpbridge
```

**Test mcpbridge manually:**
```bash
echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}' | xcrun mcpbridge
```

**Get Xcode PID:**
```bash
ps aux | grep "Xcode.app/Contents/MacOS/Xcode" | grep -v grep | awk '{print $2}'
```

**Check Xcode MCP setting:**
```bash
defaults read com.apple.dt.Xcode | grep -i "mcp\|model.*protocol"
```

---

**Last Updated:** 2026-02-07  
**Xcode Version:** 16.3 RC  
**Project:** Reefy (tvOS Jellyfin Client)
