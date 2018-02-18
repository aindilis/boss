BOSS

Boosting Open Source Software

Software engineering manager for project management

BOSS coordinates the software development of our internal codebases,
the applications that we are writing to either effectively glue
together external codebases as in most cases or as mostly independent
projects (like Gourmet).  BOSS converses with Architect to coordinate
development of icodebases with respect to overall goals, and RADAR and
Machiavelli to provide a project development simulator for use in
reasoning about other projects, and in general, to answer software
development questions.  BOSS also automates many of the aspects of
writing codebases.

It is an agent, which communicates over (UniLang/FL/etc.) which is
responsible for several tasks related to source and project
management/development.

Handle setup of preferences for tools used in creating software.

Ability to create project, or to run tests and recommend/implement
changes to project structure to make them compatible with our
development model.

Have an update-rc.d like system that handles the following things: It
scans a project for information about hooks that it must register with
the system BEFORE they get packaged, so that we can test, develop and
use these features, without having to build and install the package
for every single change, i.e.

Yet, when the package is installed, it intelligent selects which hooks
ought to be activated between the package and the source system, on
certain criteria, and allows hot swapping.

Create an FRDCSA distribution CD or DVD on demand.  Perhaps, use
KNOPPIX as a starter.

http://frdcsa.org/frdcsa/internal/boss