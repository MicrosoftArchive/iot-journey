<img alt="Microsoft" src="docs/figures/ms-logo.png" style="float:right">
![patterns & practices](docs/figures/pnp-logo.png)
# An IoT Journey

## Why

There is no one-size-fits-all answer when it comes to building an IoT solution.
Our approach to guidance is to embark on a collaborative journey into
understanding the mechanics and challenges surrounding an end-to-end system.
Our purpose is _not_ to tell you all the answers that you'll need, but rather to
help you ask the right questions.

## What

We will be constructing an IoT solution hosted in Azure. We will be using the
same tools and services that are available to you. Instead of a single final
snapshot of our source code, we'll be sharing the history and intermediate
[releases][]. We'll grow the _reference implementation_ (our fancy name for an
end-to-end sample) over time; responding to new business requirements and
taking advantage of new services as they are released.

In addition to the source code, we'll also produce a set of written guidance to
provide explanations, context, and anything else that necessary to.

We intend this to be an interactive act of discovery.

## How

We've constructed a [scenario][] that reflects business requirements we've
gathered from customers and advisors. The scenario is not meant to be realistic,
but rather representative. That is, it should represent the most command needs
and [challenges][] you will face. (We'd like your immediate feedback on the
[scenario][] to help make sure that it is truly representative.)

We'll use this scenario to define our [backlog][] for the reference
implementation. Both the scenario and backlog will change over time. We'll
deliberately break the scenario up into _phases_. Each phase will have a
specific set of goals, deliverables, and target dates. We will tag the source as
a [release][releases] at the end of each phase. Our engineering team will be
working in two week iterations against the backlog.

We will also establish an advisory council with regular meetings. The council
will be asked to continuously review our work and provide critical feedback.

Likewise, we intend to keep the conversation open. Any and all feedback is
welcome.

> This a conversation not a dictation.

## Who

Our intended audience for this guidance is any senior developer or architect
interested in developing an IoT solution. Our reference implementation will
primarily target the .NET platform, however we will aim to make the written
guidance platform agnostic as we reasonably can. It is likely that we will be
discussing various open source and non-.NET technologies as well.
If you feel that there is anything more that we can do to make this guidance
accessible to a broader audience, you are encouraged to share.

## FAQ

1. If this is an IoT project, why is there so much emphasis on the backend
services and almost nothing about devices?

1. I haven't seen any activity on this project for some number of days? Does
that mean it's dead?

[scenario]: docs/Scenario.md
[challenges]: docs/Challenges.md
[backlog]: https://github.com/mspnp/iot-journey/issues
[releases]: https://help.github.com/articles/about-releases/
