# Working Task List Skill

## Mission

Track and manage tasks for current StoreScorer development work.

## When to Use

- Starting a new development phase
- Checking current task status
- Marking tasks complete
- Planning next steps

## Current Task List

Located at: `agentic/prd/working/001-tasks-v2-migration.md`

## Workflow

### Check Status

1. Read current task file
2. Identify completed phases
3. Find next incomplete task

### Update Task

1. Mark task as complete with [x]
2. Add any notes or blockers
3. Commit task list update with phase commit

### Add New Task

1. Add task in appropriate phase
2. Number sequentially (Task X.Y)
3. Keep description actionable

## Task Conventions

- Use `[x]` for complete, `[ ]` for incomplete
- Group by phase
- Keep tasks small (< 1 hour each)
- Include commit message template for each phase

## Example

```markdown
## Phase 5: API Route Migration
- [x] Task 5.1: Migrate /api/audit routes
- [ ] Task 5.2: Migrate /api/user routes
```
