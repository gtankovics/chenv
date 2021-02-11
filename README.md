# fchenv

A simple script which change the Google Cloud Platform configuration and Kubernetes cluster context in same time. 

I really need this "tool" in every day working.

### Requirements:
- Google Cloud SDK (command line tool)
- Kubernetes command line tool
- fish shell
- ENV VARIABLES
  - PRODUCTION_DOMAIN_SUFFIX
  - PILOT_DOMAIN_SUFFIX
  - DEVELOPMENT_DOMAIN_SUFFIX
  - GCLOUD_CONFIGURATIONS_PATH default: ~/.config/gcloud/configurations 

### Installation

Just run `finstall.sh`.

### Usage

```
Usage:
        fchenv [options]

Options:
        help    Show this help.
        list    Show list of valid environments.
                Extra options:
                details                 List environments with details
                prod or production      List 'production' environment(s)
                edu or educational      List 'educational' environment(s)
                pilot                   List 'pilot' environment(s)
                qa                      List 'qa' environment(s)
                test                    List 'test' environment(s)
        set     Set the selected environment for 'gcloud' and 'kubectl'.
        reload  Reload the current environment.
        clear   Clear the variables and unset 'kubectl' context and set `default` 'gcloud' profile
```

### Extras

It works with my [fish_prompt](https://github.com/gtankovics/fish-shell/)

### chenv (old version)

Requirements:
- Google Cloud SDK (command line tool)
- Kubernetes command line tool
- fish shell
- ENV VARIABLES
  - PRODUCTION_DOMAIN
  - PILOT_DOMAIN
  - DEV_DOMAIN


```
Usage:
        chenv [options]

Options:

        list                    list all environments
        [ENVIRONMENT_NAME]      change 'gcloud' and 'kubectl' contexts
        reload                  reload the current environment

```

> It does not have autosuggestion or filtering features.