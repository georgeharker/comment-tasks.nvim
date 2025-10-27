# Trello Integration
## Setup

### 1. Get API Credentials

#### API Key
1. Go to [Trello Developer API Keys](https://trello.com/app-key)
2. Copy your "Key" (this is your API key)

#### Token  
1. On the same page, click "Token" link
2. Authorize the application
3. Copy the generated token

### 2. Environment Configuration

```bash
export TRELLO_API_KEY="your_trello_api_key_here"
export TRELLO_TOKEN="your_trello_token_here"
```

### 3. Plugin Configuration

```lua
require("comment-tasks").setup({
    providers = {
        trello = {
            enabled = true,
            api_key_env = "TRELLO_API_KEY",
            token_env = "TRELLO_TOKEN",
            board_id = "your_board_id",         -- Required: Trello board ID
            list_id = "your_list_id",           -- Required: Default list ID for new cards
            
            -- Optional: Default labels for new cards
            default_labels = ["red", "blue"],    -- Label colors or IDs
            
            -- Optional: Default members to assign
            default_members = ["member_id"],     -- Member IDs
        }
    }
})
```

### 4. Finding Your IDs

#### Board ID (Required)

**Method 1: From Trello URL**
```
https://trello.com/b/[BOARD_ID]/board-name
                     ↳ This is your board_id
```

**Method 2: Using API**
```bash
curl "https://api.trello.com/1/members/me/boards?key=YOUR_API_KEY&token=YOUR_TOKEN"
```

#### List ID (Required)

**Method 1: From browser developer tools**
1. Open your board in Trello
2. Open browser developer tools (F12)
3. Right-click on a list → Inspect element
4. Look for `data-id` attribute

**Method 2: Using API**
```bash
curl "https://api.trello.com/1/boards/BOARD_ID/lists?key=YOUR_API_KEY&token=YOUR_TOKEN"
```

## Usage

### Commands

Trello uses a list-based workflow (cards move between lists):

```vim
:TrelloTask new          " Create card in configured list
:TrelloTask move         " Move card to different list (requires list_id)
:TrelloTask addfile      " Add current file as attachment to card
```

### Moving Cards Between Lists

Since Trello is list-based, you can configure multiple lists:

```lua
trello = {
    enabled = true,
    api_key_env = "TRELLO_API_KEY", 
    token_env = "TRELLO_TOKEN",
    board_id = "abc123def456",
    list_id = "todo_list_id",       -- Default "To Do" list
    
    -- Optional: Configure additional lists for workflow
    lists = {
        todo = "todo_list_id",
        doing = "doing_list_id", 
        review = "review_list_id",
        done = "done_list_id"
    }
}
```

With list configuration, you can move cards:

```vim
:TrelloTask move doing   " Move card to "Doing" list
:TrelloTask move review  " Move card to "Review" list  
:TrelloTask move done    " Move card to "Done" list
```

### Example Workflow

1. **Create a card**:
   ```css
   /* TODO: Improve responsive design for mobile screens */
   /* Current layout breaks on screens smaller than 768px */
   ```
   
   Place cursor on comment → `:TrelloTask new`
   
   ```css
   /* TODO: Improve responsive design for mobile screens */
   /* Current layout breaks on screens smaller than 768px */
   /* https://trello.com/c/abc123def */
   ```

2. **Move card through workflow**:
   ```vim
   :TrelloTask move doing   " When you start working
   :TrelloTask move review  " When ready for review
   :TrelloTask move done    " When completed
   ```

3. **Add file attachments**:
   ```vim
   :TrelloTask addfile      " Attaches current file to the card
   ```

## Configuration Options

### Basic Configuration

```lua
trello = {
    enabled = true,
    api_key_env = "TRELLO_API_KEY",
    token_env = "TRELLO_TOKEN", 
    board_id = "abc123def456",
    list_id = "default_list_id",    -- Default list for new cards
}
```

### Advanced Configuration

```lua
trello = {
    enabled = true,
    api_key_env = "TRELLO_API_KEY",
    token_env = "TRELLO_TOKEN",
    board_id = "abc123def456", 
    list_id = "todo_list_id",
    
    -- Optional: Multiple list workflow
    lists = {
        backlog = "backlog_list_id",
        todo = "todo_list_id", 
        doing = "doing_list_id",
        review = "review_list_id",
        testing = "testing_list_id", 
        done = "done_list_id"
    },
    
    -- Optional: Default labels (by color or ID)
    default_labels = ["red", "blue", "green"],
    
    -- Optional: Default members to assign (by ID)
    default_members = ["member_id_1", "member_id_2"],
    
    -- Optional: Card template
    card_template = {
        description_prefix = "## Description\\n",
        description_suffix = "\\n## Checklist\\n- [ ] Implement\\n- [ ] Test\\n- [ ] Document"
    },
    
    -- Optional: Position for new cards
    card_position = "top",      -- "top" or "bottom" of list
}
```

## Troubleshooting

### "Board not found" or "Invalid board_id"

1. **Verify board ID**:
   ```bash
   curl "https://api.trello.com/1/boards/BOARD_ID?key=API_KEY&token=TOKEN"
   ```

2. **Check permissions**: 
   - Ensure you're a member of the board
   - Verify board isn't private (if you're not a member)

3. **API access**: Confirm API key and token have board access

### "List not found" or "Invalid list_id"

1. **Check available lists**:
   ```bash
   curl "https://api.trello.com/1/boards/BOARD_ID/lists?key=API_KEY&token=TOKEN"
   ```

2. **List permissions**: Ensure list exists and isn't archived

### Authentication Issues

1. **API Key verification**:
   ```bash
   curl "https://api.trello.com/1/members/me?key=API_KEY&token=TOKEN"
   ```

2. **Token expiry**: Tokens can expire - regenerate if needed

3. **Scope permissions**: Ensure token has read/write access

### Cards Not Creating

1. **List permissions**: Check if you can manually add cards to the list
2. **Board access**: Verify you have write access to the board
3. **Rate limits**: Trello has API rate limits (300 requests per 10 seconds)

## API Reference

Trello uses the [REST API v1](https://developer.atlassian.com/cloud/trello/rest/). The plugin makes requests to:

- `POST /1/cards` - Create cards
- `PUT /1/cards/{id}` - Update card details and position
- `GET /1/cards/{id}` - Retrieve card information
- `POST /1/cards/{id}/attachments` - Add file attachments

## Workflow Examples

### Kanban Development Workflow

```lua
trello = {
    lists = {
        backlog = "backlog_list_id",       -- Ideas and future work
        todo = "todo_list_id",             -- Ready for development
        doing = "doing_list_id",           -- Currently in progress
        review = "review_list_id",         -- Code review stage
        testing = "testing_list_id",       -- QA testing stage  
        done = "done_list_id"              -- Completed work
    }
}
```

Usage:
```vim
:TrelloTask new          " Create in backlog
:TrelloTask move todo    " Move to ready for work
:TrelloTask move doing   " Start working
:TrelloTask move review  " Ready for review
:TrelloTask move done    " Complete
```

### Label-Based Categorization

```lua
trello = {
    -- Use labels for categorization
    label_mapping = {
        bug = "red",
        feature = "blue", 
        improvement = "green",
        technical_debt = "yellow"
    }
}
```

### Team Assignment

```lua
trello = {
    -- Assign different members based on work type
    member_assignment = {
        frontend = ["frontend_dev_id"],
        backend = ["backend_dev_id"], 
        design = ["designer_id"]
    }
}
```

## Integration Tips

1. **Board organization**: Use separate boards for different projects
2. **List workflow**: Design lists to match your team's process
3. **Label consistency**: Use consistent labeling across boards
4. **File attachments**: Use `:addfile` to maintain code references
5. **Card templates**: Set up templates for consistent card structure

For more examples, see [../examples/workflows.md](../examples/workflows.md#trello-workflows).
