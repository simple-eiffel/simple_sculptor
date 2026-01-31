# Phase 2: Adversarial Contract Review - Instructions

## Overview

Phase 2 uses a progressive chain of 4 AI reviews to find contract problems BEFORE implementation. Each AI builds on the previous findings.

**Review Chain**: Ollama → Claude → Grok → Gemini

## Quick Start

**Step 1: Copy and Submit Ollama Prompt**

```bash
cat .eiffel-workflow/prompts/phase2-ollama-review.md
```

Copy entire output → paste to Ollama → wait for response

**Step 2: Save Ollama's Response**

```bash
# Save Ollama's response to this file:
.eiffel-workflow/evidence/phase2-ollama-response.md
```

**Step 3: Prepare Claude Prompt**

Open: `.eiffel-workflow/prompts/phase2-claude-review.md`

Find the section:
```
## Ollama's Review (Previous AI - paste here)

```
[PASTE OLLAMA'S RESPONSE HERE - this section will be populated by the user]
```
```

Paste Ollama's response between the backticks.

**Step 4: Submit to Claude**

Copy entire prompt → Open a NEW Claude Code session → paste prompt

Save Claude's response to: `.eiffel-workflow/evidence/phase2-claude-response.md`

**Step 5-6: Repeat for Grok**

Same process:
1. Open `.eiffel-workflow/prompts/phase2-grok-review.md`
2. Paste Ollama + Claude responses where indicated
3. Submit to Grok
4. Save response to `.eiffel-workflow/evidence/phase2-grok-response.md`

**Step 7-8: Repeat for Gemini**

Same process:
1. Open `.eiffel-workflow/prompts/phase2-gemini-review.md`
2. Paste Ollama + Claude + Grok responses where indicated
3. Submit to Gemini
4. Save response to `.eiffel-workflow/evidence/phase2-gemini-response.md`

**Step 9: Return Here**

Say: `reviews complete`

I will then generate `synopsis.md` with all findings aggregated.

## What Each AI Looks For

### Ollama: Basic Issues
- Preconditions that are too weak
- Postconditions that don't constrain anything
- Missing invariants
- Edge cases not covered
- Obvious logical errors

**Questions Ollama answers:**
- What's obviously broken?
- What preconditions are useless?
- What postconditions need strengthening?

### Claude: MML & Semantics
- Semantic correctness (do contracts mean what author intended?)
- MML (Mathematical Modeling Language) completeness
- Frame conditions (what didn't change? is it stated?)
- Old-state reasoning (`old` expressions)
- Void safety patterns

**Questions Claude answers:**
- Are contracts semantically correct?
- Should we use MML model queries?
- Are frame conditions sufficient?
- Are detachable attributes handled properly?

### Grok: Edge Cases & Adversarial
- Boundary conditions (what if x = 0.1 exactly? x = 1.0 exactly?)
- Resource exhaustion (memory, file I/O failures)
- Invalid inputs (NaN, Inf, empty arrays)
- Adversarial scenarios (user trying to break contracts)
- Type confusion (wrong types, case sensitivity)

**Questions Grok answers:**
- What edge cases might violate contracts?
- What scenarios aren't covered?
- Can users construct inputs that break postconditions?
- What resources might be exhausted?

### Gemini: Final Synthesis & Recommendation
- Aggregates all three previous reviews
- Identifies which issues are CRITICAL vs HIGH vs MEDIUM vs LOW
- Assesses overall contract quality (score/5)
- Provides risk assessment
- Makes final recommendation:
  - ✓ APPROVE (contracts ready for Phase 4)
  - ⚠️ APPROVE WITH FIXES (fixable issues, provide change list)
  - ✗ REJECT (fundamental problems, back to Phase 1)

**Questions Gemini answers:**
- Are contracts ready for implementation?
- What must be fixed before Phase 4?
- What's the risk level if we proceed?
- Final recommendation: proceed or fix?

## Files Involved

### Prompts (ready to submit)
- `prompts/phase2-ollama-review.md` - ✓ Ready now (fully pre-populated)
- `prompts/phase2-claude-review.md` - Paste Ollama response
- `prompts/phase2-grok-review.md` - Paste Ollama + Claude responses
- `prompts/phase2-gemini-review.md` - Paste all 3 responses

### Evidence (where responses go)
- `evidence/phase2-ollama-response.md` - Ollama's findings
- `evidence/phase2-claude-response.md` - Claude's findings
- `evidence/phase2-grok-response.md` - Grok's findings
- `evidence/phase2-gemini-response.md` - Gemini's final verdict + synthesis
- `evidence/phase2-chain.txt` - This review chain tracking document

### Supporting Files
- `approach.md` - Implementation strategy sketch (submitted with prompts)
- `PHASE2_INSTRUCTIONS.md` - This file
- (To be generated) `synopsis.md` - Final synthesis of all findings

## Timeline Estimate

| Step | AI | Estimated Time | Notes |
|------|----|----|-------|
| 1 | Ollama | 5-10 min | Find basic issues |
| 2 | Claude | 5-10 min | Deeper semantic analysis |
| 3 | Grok | 5-10 min | Edge cases & adversarial |
| 4 | Gemini | 5-10 min | Final verdict |
| 5 | Claude Code | 2-3 min | Generate synopsis |
| **TOTAL** | - | **~30-40 min** | All 4 reviews + synthesis |

## Expected Findings

Based on the skeleton contracts created in Phase 1, the reviews might find:

**Likely Critical Issues:**
- Frame conditions missing (what config stays unchanged?)
- Error handling gaps (file I/O, ONNX loading failures)
- Coordinate validation missing (NaN/Inf not validated)
- Mesh topology validation (face indices unchecked)

**Likely High Issues:**
- Empty error messages violating XOR invariant
- Weak preconditions on file paths
- Missing MML model queries for collections
- Insufficient postcondition detail

**Likely Medium Issues:**
- Documentation of edge cases
- Frame conditions in postconditions
- Clearer error semantics

**Likely Low Issues:**
- Performance hints
- Alternative postcondition wording
- Test coverage suggestions

## What Happens Next

### If Gemini Says APPROVE
✓ Proceed to Phase 3 (Task Decomposition)
- Contracts are frozen
- Implementation can begin in Phase 4
- No changes needed

### If Gemini Says APPROVE WITH FIXES
⚠️ Make contract changes, then proceed
- Gemini provides specific change list
- I make the fixes to contracts
- Possibly resubmit critical issues for verification
- Then proceed to Phase 3

### If Gemini Says REJECT
✗ Go back to Phase 1 redesign
- Fundamental contract problems
- Need to redesign classes/contracts
- Very unlikely at this point

## Tips for Success

1. **Use copy-paste**, not manual typing
2. **Keep AI session context short** - use separate sessions for each review
3. **Include all preamble text** when submitting prompts (contracts are embedded)
4. **Save responses immediately** - don't lose AI findings
5. **Be precise with formatting** when pasting responses (maintain markdown)

## Detailed Workflow

### Step 1: Ollama Review

**You do:**
1. Open file: `.eiffel-workflow/prompts/phase2-ollama-review.md`
2. Copy entire contents (all ~800 lines)
3. Paste to Ollama chat
4. Wait for response (Ollama will take 5-10 minutes)
5. Copy Ollama's response
6. Save to: `.eiffel-workflow/evidence/phase2-ollama-response.md`

**Ollama will:**
- Review all 14 classes
- List issues in format:
  ```
  ISSUE: [description]
  LOCATION: [class.feature]
  SEVERITY: [CRITICAL/HIGH/MEDIUM/LOW]
  SUGGESTION: [how to fix]
  ```

### Step 2: Claude Review

**You do:**
1. Open file: `.eiffel-workflow/prompts/phase2-claude-review.md`
2. Find section "Ollama's Review (Previous AI - paste here)"
3. Replace `[PASTE OLLAMA'S RESPONSE HERE...]` with actual Ollama response
4. Copy entire edited file
5. Open a **NEW Claude Code session** (or Claude.ai session)
6. Paste the prompt
7. Wait for response
8. Copy Claude's response
9. Save to: `.eiffel-workflow/evidence/phase2-claude-response.md`

**Claude will:**
- Review with focus on MML and semantics
- List issues in format:
  ```
  CLAUDE_ISSUE: [description]
  LOCATION: [class.feature]
  SEVERITY: [CRITICAL/HIGH/MEDIUM/LOW]
  MML_RELEVANT: [yes/no]
  SUGGESTION: [how to fix]
  RATIONALE: [why this matters]
  ```

### Steps 3 & 4: Grok & Gemini

Repeat Step 2 process:
1. Edit prompt file with previous responses
2. Submit to AI
3. Save response to evidence file

## File Locations Reference

```
simple_sculptor/
├── .eiffel-workflow/
│   ├── approach.md                      ← Implementation strategy
│   ├── PHASE2_INSTRUCTIONS.md           ← This file
│   ├── prompts/
│   │   ├── phase2-ollama-review.md     ← SUBMIT THIS FIRST
│   │   ├── phase2-claude-review.md     ← EDIT & SUBMIT SECOND
│   │   ├── phase2-grok-review.md       ← EDIT & SUBMIT THIRD
│   │   └── phase2-gemini-review.md     ← EDIT & SUBMIT FOURTH
│   └── evidence/
│       ├── phase2-chain.txt             ← Tracking document
│       ├── phase2-ollama-response.md   ← SAVE OLLAMA HERE
│       ├── phase2-claude-response.md   ← SAVE CLAUDE HERE
│       ├── phase2-grok-response.md     ← SAVE GROK HERE
│       └── phase2-gemini-response.md   ← SAVE GEMINI HERE (final verdict)
├── src/                                 ← 14 classes (reviewed)
├── test/                                ← 6 test classes (reviewed)
└── simple_sculptor.ecf                  ← Configuration
```

## Troubleshooting

**Q: Ollama is slow / timed out**
A: Try submitting shorter versions or use a different local LLM

**Q: Can I skip an AI?**
A: Yes - you need at least 1 external review. Gemini can aggregate from any previous reviews.

**Q: What if one AI contradicts another?**
A: That's valuable! Gemini will address disagreements in final synthesis.

**Q: Should I edit AI responses before saving?**
A: No - save exactly what the AI produced (you can add a header with timestamp/model name)

**Q: What if an AI finds something I disagree with?**
A: Let Gemini decide - that's what the synthesis is for. You review Gemini's final verdict.

## Success Criteria

Phase 2 is COMPLETE when:
✓ All 4 AI reviews submitted
✓ All responses saved to evidence/ directory
✓ phase2-gemini-response.md contains Gemini's final verdict
✓ Verdict is APPROVED or APPROVED WITH FIXES (not REJECTED)
✓ User explicitly approves proceeding to Phase 3

---

**Status**: Ready to begin

**Next action**: Copy `prompts/phase2-ollama-review.md` and submit to Ollama

**When done**: Return here and say "reviews complete"
