AWS Scripts & Templates
=======================

A basic repository containing various useful CLI scripts and CloudFormation
templates I've written and/or used previously. Some of these are used
by my Jenkins servers to launch, update, and maintain various peices of my
infrastructure. CLI code is needed to bridge the gap for peices that the
CloudFormation API misses. Alternative suggestions welcome!

### Requirements

Many of the examples here require these:

- `yum install jq -y`
- [AWS CLI](http://aws.amazon.com/cli/) - Typically `pip install awscli`. You may need to `yum install python-pip -y` first.

### AWS Scripts

Found in the `./scripts` directory.

### AWS Checks

Several (Nagios / Sensu / etc) checks used to evaluate AWS health. Found
in the `./checks` directory.

### AWS Cloudformation Templates

There are two variations of templates available in the repo.
`./templates/troposphere/*` contains python templates that output to the
correct JSON format. You can build the templates by running the `./build.sh`
script located in the troposhere directory.

Prebuilt versions of the JSON templates are available under
`./templates/cloudformation/*`.

### Links

View my blog at [www.justinfox.me](http://www.justinfox.me).
