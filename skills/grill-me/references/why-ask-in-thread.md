# Why Grill Me Asks in Thread

This note is for people reading or forking the skill.
It is deliberately kept out of `SKILL.md`, because everything in that file is loaded into the model's context on every invocation and this reasoning is not something the model needs in order to follow the rule.

The rule is that questions are asked as ordinary text in the conversation rather than through the harness question or ask tool.
There are two reasons, and both are about how those tools behave rather than about style.

The first is capacity.
The question tools in agent harnesses cannot carry enough context to pose or answer a complex, detailed question, which is exactly the kind of question this skill exists to ask.
A question worth stopping for usually needs several paragraphs of evidence and trade-offs before its options mean anything, and the options themselves need room to state real differences.

The second is failure on timeout.
The tool gets called, the user has moved on to something else, the call errors out, and the whole question has to be asked again from scratch.

Asking in thread avoids both problems, because the question simply waits in the transcript until the user comes back to it.
