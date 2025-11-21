---
applyTo: '**'
description: 'Copilot thought logging for persistent memory - see the process Copilot is following where you can edit to reshape interaction or save for follow-up'
---

# Copilot Thought Logging Instructions

> **Purpose**: Maintain persistent Copilot memory across all projects through structured thought logging

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

- Check if `.github/copilot-config.yml` exists (path relative to workspace root)
- If config file doesn't exist, create it with complete default configuration:
  - `logging.max_log_size_mb`: 10
  - `logging.memory_file_pattern`: "Copilot-Processing-YYYY-MM-DD.md"
  - `logging.rotated_memory_pattern`: "Copilot-Processing-YYYY-MM-DD-HHmmssSSS.md"
  - `logging.memory_location`: "../copilot-global-memory/thought-logs"
  - `logging.memory_symlink_name`: ".github/.copilot-memory"
  - `session_metadata.include_timestamp`: true
  - `session_metadata.include_project_name`: true
  - `session_metadata.include_workspace_path`: true
  - `session_metadata.include_branch`: true
  - `session_metadata.include_user_request`: true
- Read configuration from `.github/copilot-config.yml` to get all logging and session_metadata settings
- For any missing configuration entries, add them to the config file with their default values listed above
- Note: The config file is the single source of truth once it exists, but the instructions define the initial defaults
- Check if the symlink specified by config: `memory_symlink_name` exists at the path given in the config
- If symlink does not exist, create it pointing to the memory_location path
- Ensure the target directory exists (create if needed)
- Check if the root `.gitignore` file in the workspace contains an entry for either the memory symlink path (from config: memory_symlink_name) **OR** the global memory directory pattern (from config: memory_location, as a directory pattern)
- If neither is present, append the memory symlink path to the root `.gitignore` file with a comment explaining it's for Copilot memory (e.g., "# Copilot memory symlink; global memory directory can be tracked separately if desired")
- Determine the current memory file name using memory_file_pattern, substituting today's date
- If the current memory file does not exist, create it
- If the current memory file exists and exceeds the max_log_size_mb threshold, rotate it by renaming using rotated_memory_pattern and create a new file
- Append to the current log file with session details based on session_metadata configuration:
  - Timestamp in ISO 8601 format (if include_timestamp is true)
  - Project/repository name (if include_project_name is true)
  - Workspace path (if include_workspace_path is true)
  - Current branch (if include_branch is true and git repository)
  - User request details (if include_user_request is true)
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

- Add summary to the current log file `.github/.copilot-memory/Copilot-Processing-YYYY-MM-DD.md`
- Work silently without announcements until complete.
- Execute only when ALL actions complete
- Inform user: "Added final summary to `.github/.copilot-memory/Copilot-Processing-YYYY-MM-DD.md`."
- Remind user that `.github/.copilot-memory` symlink should be added to `.gitignore` if not already present.
- Inform user that the parent-level `copilot-global-memory/thought-logs` directory serves as Copilot's persistent memory system and can be maintained as a separate git repository for global memory across all projects.
- If the symlink or copilot-global-memory directory was created during Phase 1, remind user to:
  - If Phase 1 was skipped or failed, add `.github/.copilot-memory` to `.gitignore` to exclude the memory symlink from version control
  - Initialize the copilot-global-memory directory as a git repository if desired for version control
  - Set up automated log scrubbing/sanitization processes to remove sensitive information
  - Configure log retention policies and backup strategies
  - Review and sanitize logs regularly before committing to any repository
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