# Introduction to OpenStack HEAT : DevOpsPro 2016

OpenStack HEAT is a flexible and extensible orchestration tool which allows
you to use your OpenStack IaaS to repeatably deploy clusters of
servers, networks, services, and other infrastructure.


This workshop will provide a quick introduction to the use of OpenStack's
HEAT project to repeatably deploy multi-component applications.

## Sections

* Examples
    1. A [simple example](lessons/lesson1.md) of a single VM. In this example we'll
      show the SIMPLEST possible OpenStack HEAT template. This is the
      "hello world" of HEAT, and introduces us to the YAML DSL, and the
      overall structure of a HOT. We'll also get a look at the various
      components of the [Horizon](glossary.md#Horizon) UI, including the
      deployment, stack view, and instance screens.
    2. Not everything can be done via the UI. In the next lesson we'll
      take a look at the OpenStack [HEAT CLI](lessons/lesson2.md), and use it
      to re-deploy the first example via the command line. This command
      line tool is very useful for automating the HOT deployment from
      external applications; ie: automatic deployment via Jenkins CI/CD.
    3. How to create a [parameterized HOT](lessons.lesson3.md) template. Creating
      HOT YAML with hardcoded image/network/naming is a bad practice. To
      avoid having multiple copies of your templates for different environments,
      you can parameterize them to be customized at deployment time.
    4. We add [Templating and User Data](lessons/lesson4.md) to our template. This allows
      us to customize our Virtual Machines when we deploy them by running a script
      when the VM is deployed. There is also a templating feature that allows us
      to reuse our _parameters_ and _resources_ as variables in those
      scripts.
    5. [ResourceGroups](lessons/lesson5.md) give us the ability to deploy multiple
      copies of a given set of resources. This lets us do things like create
      a cluster of identical servers, networks or other resources.
* Appendix
    * [Pre-requisites](prerequisites.md) for these lessons
    * [Glossary](glossary.md)
