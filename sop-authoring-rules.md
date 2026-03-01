# Rules for Creating SOPs

These rules govern how SOPs are created and updated. They are not an SOP; they’re a meta-guide for the AI that creates SOPs.

## Scope

The AI - upon reading this document - may update the entire SOP it’s asked to update, instead of only making the changes needed to handle the new problem/edge case. This is a spotlight-effect failure mode.

When a user asks to update an SOP using this guide, apply it only to the parts that must change to address the problem—unless the user explicitly wants an overhaul.

## 1. Do Not Infantize the AI
- **Assumption**: The AI executing the SOP is capable and intelligent.
- **Rule**: Do not provide overly prescriptive instructions for tasks the AI naturally understands (e.g., identifying a car rental email, reading a date). 
- **Exception**: Only be prescriptive if a specific process is known to be error-prone or counter-intuitive (e.g., a misleading website UI).

## 2. Use Normal English (No MBA/Government Speak)
- **Avoid Authority**: Do not use words like "unauthorized", "strictly", "mandatory", or "authority" unless there is actual enforcement/punishment capability.
- **Rule**: State what should be done simply. If it's not a punishable offense, don't sound like it is.
- **Avoid**: "Creation of subfolders is unauthorized." "It's non-negotiable that no subfolders can be created in this folder." "Mandantory rule: no subfolder allowed here."
- **Prefer**: "Keep the structure flat."

## 3. Test the SOP, Not the Prompt
- **Context**: When updating an SOP, we often verify it by running a test agent (e.g., `claude -p`).
- **Rule**: Do not put the expected result or the new rule *into the test prompt*. The test prompt should be minimal to see if the SOP *itself* guides the agent to the right result.
- **Bad Test Prompt**: "Run the SOP and ensure you flatten the folder structure." (This passes even with a bad SOP).
- **Good Test Prompt**: "Run the SOP on this folder." (This only passes if the SOP effectively guides the flattening).
- **AI Role Clarification**: When asked to test/update an SOP, the AI's goal is to produce a WORKING SOP, not to solve the problem directly. The AI should author/fix the SOP and test it by invoking another agent (e.g., `claude -p "Follow sop.md..." > output.log 2>&1`), then analyze the captured output to identify failures. The AI should never directly execute the SOP steps itself - that defeats the purpose of testing whether the SOP is written clearly enough for another AI to follow.
- **Practical Constraint**: Long-running SOPs will hit tool timeout limits when invoked. Capture output to a file for later analysis rather than trying to monitor in real-time. The authoring process aims to produce working SOPs, not to solve immediate problems.

## 4. No Cheating (Avoid Overfitting)
- **Rule**: Do not use the exact data from the test case as the example in the SOP.
- **Reasoning**: If the SOP's example matches the test data exactly, the AI might just copy the example rather than applying the general rule (overfitting).
- **Guideline**: Use generic or different examples than the ones used for verification.

## 5. Single Source of Truth (SSOT)
- **Rule**: Define methods (e.g., "How to access Dropbox") in ONE place only.
- **Implementation**: If an SOP needs to refer to a method defined elsewhere, reference that SOP. Do *not* repeat the instructions.
- **Reasoning**: Repeating instructions creates maintenance debt. If the method changes (e.g., Dropbox to OneDrive), you'd have to update every file. With SSOT, you update only one.

## 6. Prevent Spotlight Effect
- **Definition**: The tendency to over-correct or over-emphasize a rule because a specific problem was just discovered.
- **Signs**: Adding massive blocks of text for a small fix, or using words like "**Critical**", "Importantly", "You MUST".
- **Rule**: Fix the problem proportionally. Often, a subtle change (like renaming a title or adjusting a sentence) is enough. If not, sometimes re-ordering the sop so important / critical components appear earlier, so the AI reading it gets to know at the outset rather than mis-understanding an SOP only to be corrected in later text of somethign "critical" and "important".
- **Guideline**: Improving the structure or context is better than shouting with "CRITICAL" tags.
- **Existing patchwork**: Sections like "Important Notes" or "Critical Reminders" are often symptoms of past spotlight effect. When such a section contains bullets related to the problem being solved, absorb those specific bullets into the relevant procedure steps and delete them from the patchwork section. Do not overhaul the entire section unless the user explicitly wants an overhaul.

## 7. Abstract. Take time to think
- **Problem**: When content is overfitted to one test case, the instinct is to delete it. The next test run then fails because the guidance is gone entirely.
- **Rule**: When fixing overfitting, find the general principle the overfitted content was trying to express and rewrite it at that level.
- **Signs you are deleting instead of abstracting**: The ÆSOP gets shorter after a fix but the next test fails on something the old version got right.
- **Example**: "CC the relevant on-site manager" (overfitted to one email) → "include the people who need to act on this" (abstracted). Not deleted.

