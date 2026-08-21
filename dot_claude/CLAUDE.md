## Who Is This

I'm Sean.  You are my agent.  We will be working together a lot, so I thought it would be worth introducing myself.

I love to build.  I focus on building complex things as simple as possible.  I love discovering the latest tech and forking or adapting it to find ways to accomplish what I want while also find ways to reduce complexity when solving problems.

Here are some of my preferences so we can be more aligned as we work together.

## General Coding Preferences

- Keep things simple.  Channel "YAGNI" energy unless told otherwise.
- Typesafety is useful, take advantage of it.
- You are encouraged to propose bold ideas if they can meaningfully benefit our work.
- Be careful with destructive actions that are not explicitly requested by the user.
- Tests are good!  Endless smoke tests, "regression tests" for feature deletions, etc., much less good.  Tests should
be focused, not slop.
- Comments are a great way to clarify functionality and how code is used for both the user and any future agent.  Do not
comment every line but feel free to describe (concisely) how functions are used above function definitions, classes, etc.
- Keep comments up to date!  When making changes, it's vital to keep things in sync.

## Coding Preferences (PowerShell focused)

TBD

## Coding Preferences (Python focused)

- I prefer using astral.sh stack:  UV, Ruff, Ty

## Coding Preferences (Typescript focused)

- 'any' is the enemy. Inferred types are our friend. Our systems should adapt to changes, instead of requiring changes
everywhere.
- If your TS code looks like a Python dev wrote it, it is bad TS code.
- Avoid one-line functions that are just casting wrappers.
- Write TypeScript in ways that Matt Pocock and Theo would be proud of.
- If not already specified in project, I generally like to use the following tech: Convex, Tailwind, React, Vite, Bun/pnpm
- When building more complex web and react native apps, I like to pull in Zustand, React Query, Tanstack Start, Clerk (or 
better-auth if selfhosting), and ArkType (or zod if perf isn't an issue)

## Questions are read-only

- A question is a request for an answer, not for code changes.  If the message opens with "how hard would it be", "what are
your thoughts", "why does", "should we" etc.: answer it but DO NOT imply that it is an instruction to change how we are doing
things.
- If the answer is obvious and the change is trivial, still answer first and offer the change.  Ask before making it.

## Match ceremony to the task

- Do not spawn subagents or a multi-agent panel for work a single agent can finish in one pass.  Delegation is for breadth or 
adversarial review, not for ordinary short tasks.
- When several agents do work in parallel, state file ownership up front so they do not collide.

## Visual and design work

- Do not edit real components first.  For any non-trivial UI, layout, or copy change, build several distinct static mocks, and
show them to me to review.
- Dark mode by default
- Mocks are for things that do not exist yet.  If the component already exists and the project has Storybook, show me a story
instead: it is the real component, it cannot drift from production, and it doubles as a test.

## Storybook

- Write a story when: it is a shared/presentational component, it has more than two visual states worth seeing side by side, or
you would otherwise screenshot it to show me.
- Do NOT write a story for hooks, `lib/` helpers, or data-orchestration logic.  That is unit-test work, and stories usually cost
a real browser boot on every CI run.
- **A story that has never been executed is not evidence.**  Play functions rot silently — a component can be migrated out from
under them (native `<select>` → custom combobox) and every story still "passes" because nothing ever ran it.  If a project has
`@storybook/addon-vitest`, confirm the stories are actually collected as tests before trusting them.
- Check the a11y gate can fail before believing it.  `a11y.test: 'todo'` reports violations but never fails anything — that is a
check whose success is indistinguishable from it never having run.  Sequence any flip to `'error'` AFTER the suite is green,
never before, or you just create a red build I learn to ignore.
- When a Storybook MCP server is available, query it for component props before writing code.  Never infer a prop from its name
or from another library's conventions — if it is not documented, ask me.

## PR Reviews

- Most projects will have automated AI PR code reviewers.  Do NOT let the review feedback expand the PR beyond the original goal.
Address real shortcomings, but avoid scope creep.  If issues are found that are outside of a specific PR, ask the user if you should
create a new issue ticket.

- If a review bot leaves feedback you believe is not worth addressing, reply on Sean's behalf as:

```markdown
[MODEL-SLUG] RESPONDING ON BEHALF OF Sean
---

[actual reply]
```

