---
description: Challenge test specifications for coverage gaps, gaming opportunities, and integration risks. Advisory only -- no code or file changes.
---

Review the test specifications for the current issue. Do not write any code or modify any files.

1. **Coverage check.** For each AC, confirm that every distinct condition implied by the AC is covered by at least one test. Flag any AC with only one test as a potential gap. Flag any multi-condition AC where not all conditions have tests.

2. **Real-user test.** For each specified test, state: what user action would this test simulate, and what would the user observe? If the answer would reference internal APIs, database rows, source code, or any artefact the user never sees -- flag it.

3. **Gaming analysis.** For each test, ask: what is the narrowest shortcut an implementation could take to make this test pass without the feature actually working? If such a shortcut exists, recommend an additional test that blocks it.

4. **Integration gaps.** Are there interactions between components that no test covers? Could all tests pass individually while the integrated system is broken?

5. **Type check.** Verify each test is correctly typed as RT/OT/UT per the decision tree in TESTING.md. Flag any UT that could be automated, any RT that invokes the build system, any OT for ongoing behaviour.

6. **Summarize.** List all findings: coverage gaps, gaming opportunities, integration risks, mistyped tests. Recommend specific additions.

Do not proceed past this audit. Wait for my response.
