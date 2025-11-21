---
applyTo: '**'
description: 'See process Copilot is following where you can edit this to reshape the interaction or save when follow up may be needed'
---

# Copilot Process tracking Instructions

**ABSOLUTE MANDATORY RULES:**
- You must review these instructions in full before executing any steps to understand the full instructions guidelines.
- You must follow these instructions exactly as specified without deviation.
- Do not keep repeating status updates while processing or explanations unless explicitly required. This is bad and will flood Copilot session context.
- NO phase announcements (no "# Phase X" headers in output)
- Phases must be executed one at a time and in the exact order specified.
- NO combining of phases in one response
- NO skipping of phases
- NO verbose explanations or commentary
- Only output the exact text specified in phase instructions

# Phase 1: Initialization

- Check if `/.copilot-logs` symlink exists in workspace root
- If symlink does not exist, create it pointing to `../copilot-logs` (one level up from workspace root)
- Ensure the target directory `../copilot-logs` exists (create if needed)
- Determine the current log file name: `/.copilot-logs/Copilot-Processing-YYYY-MM-DD.md` using today's date
- If the current log file does not exist, create it
- If the current log file exists and exceeds 1MB in size, rotate it by renaming to `/.copilot-logs/Copilot-Processing-YYYY-MM-DD-HHmmssSSS.md` (using hours, minutes, seconds, and milliseconds) and create a new file
- Append to the current log file with timestamp and session details including:
  - Timestamp in ISO 8601 format
  - Project/repository name
  - Workspace path
  - Current branch (if git repository)
  - User request details
- Add a separator line (e.g., `---`) between entries for readability
- Work silently without announcements until complete.
- When this phase is complete keep mental note of this that <Phase 1> is done and does not need to be repeated.

# Phase 2: Planning

- Append an action plan to the current log file under the current timestamped entry.
- Generate detailed and granular task specific action items to be used for tracking each action plan item with todo/complete status in the current log file.
- This should include:
  - Specific tasks for each action item in the action plan as a phase.
  - Clear descriptions of what needs to be done
  - Any dependencies or prerequisites for each task
  - Ensure tasks are granular enough to be executed one at a time
- Work silently without announcements until complete.
- When this phase is complete keep mental note of this that <Phase 2> is done and does not need to be repeated.

# Phase 3: Execution

- Execute action items from the action plan in logical groupings/phases
- Work silently without announcements until complete.
- Update the current log file and mark the action item(s) as complete in the tracking.
- When a phase is complete keep mental note of this that the specific phase from the current log file is done and does not need to be repeated.
- Repeat this pattern until all action items are complete

# Phase 4: Summary

- Add summary to the current log file `/.copilot-logs/Copilot-Processing-YYYY-MM-DD.md`
- Work silently without announcements until complete.
- Execute only when ALL actions complete
- Inform user: "Added final summary to `/.copilot-logs/Copilot-Processing-YYYY-MM-DD.md`."
- Remind user that `.copilot-logs` symlink should be added to `.gitignore` if not already present.
- Inform user that the parent-level `copilot-logs` directory can be maintained as a separate git repository for global memory across all projects.
- **Warning:** Logs may contain sensitive or confidential information. Always review and sanitize logs before committing them to any repository.

**ENFORCEMENT RULES:**
- NEVER write "# Phase X" headers in responses
- NEVER repeat the word "Phase" in output unless explicitly required
- NEVER provide explanations beyond the exact text specified
- NEVER combine multiple phases in one response
- NEVER continue past current phase without user input
- If you catch yourself being verbose, STOP and provide only required output
- If you catch yourself about to skip a phase, STOP and go back to the correct phase
- If you catch yourself combining phases, STOP and perform only the current phase
