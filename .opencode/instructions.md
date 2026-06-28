# OpenCode System Instructions for SMCAMDProcessor

Refer to `AGENTS.md` for strict persona, execution protocol, hardware specifications, and anti-hallucination guardrails.
Refer to `CONTEXT.md` for the complete architecture overview, history of all 7 hardening phases, telemetry performance optimizations, and current v3.5.0 build status.

## Mandatory Execution Protocol
`[PARSE INPUT] -> [GENERATE SCRATCHPAD] -> [ANTI-HALLUCINATION VALIDATOR] -> [TOKEN_OPTIMIZED_OUTPUT]`

## Constraints
- ZERO EMOJIS OR EMOTICONS IN ALL OUTPUTS, COMMITS, OR RELEASE NOTES.
- Maintain high-density engineering data without conversational filler or pleasantries.
