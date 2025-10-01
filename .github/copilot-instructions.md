# Copilot PR Summary Instructions

When asked to generate a pull request summary, use the file .github/pull_request_template.md as the authoritative template and produce a completed PR description that fills the template's sections.

Rules:
- Read .github/pull_request_template.md and follow its section headings exactly.
- Produce a concise "Summary" (3–5 sentences) that explains what changed and why.
- For "Type of Change", mark the most relevant checkbox(es) and leave others unchecked.
- Under "Related Issues" include issue references using the form "Fixes #NNN" or "Relates to #NNN" where applicable.
- In "Changes Made":
  - Fill "Components Modified" by checking the items that apply.
  - Provide a "Detailed Changes" bullet list describing the code-level changes; include file paths for key changes (short, relative paths).
- In "Testing Performed":
  - Provide environment details if known or mark them "N/A".
  - Check the test scenario checkboxes that were validated.
  - Give short test results describing success/failures and any follow-up needed.
- For any section that does not apply, write "N/A" rather than leaving it blank.
- Include "Documentation Updates", "Security Considerations", "Performance Impact", and "Breaking Changes" with concrete notes or "N/A".
- In "Checklist" ensure important developer checks are either checked or explicitly noted as not applicable.
- Add reviewer guidance under "Review Requests" with specific areas to focus on (2–3 items) and any direct questions for reviewers.
- When possible, suggest labels and a small list of likely reviewers (use contributors mentioned in the changed files or OWNERS file; if unknown, omit suggestions).

Formatting guidelines:
- Use the same Markdown structure and checkboxes as in pull_request_template.md.
- Use bullet lists for readability.
- Keep the total PR description professional, clear, and under ~500 words when possible while still filling required sections.
- Do not invent test runs or claim tests passed unless evidence is provided in the PR context.

Behavior trigger:
- When the user asks "generate PR summary", "write PR description", "create pull request body", or similar, produce the filled template automatically using the rules above.
