# Jenkins Autopilot

Spending couple of days spinning up my own instance of Jenkins in a CentOS server I decided to automate deployment process with small bash script. Currently this autopilot script works only for Docker Jenkins LTS installation. Any suggesetion and improvements are welcome.

## Prerequisites

All the Jenkins prerequisites from the offical docs: https://www.jenkins.io/doc/book/installing/docker/#prerequisites

# Usage

1. Create a folder in the system where you want your jenkins to be run `mkdir jenkins && cd jenkins`

2. Checkout repository content into this folder `git clone git@github.com:DenysPanchenko/jenkins-autopilot.git`

3. Add executable rights to the autopilot script `sudo chmod +x ./autopilot.sh`

4. Run creation of new Jenkins instance `./autopilot.sh --new`

5. After few minutes run next command to get first time login Jenkins password `./autopilot.sh --get-admin-pass`



# Other commands

There are other useful commands which you might consider in the script:
* `--clean` Stops current jenkins instance, remove all the created folders, remove docker network and container image.
* `--stop` Simply stops current running jenkins docker containers.
* `--start` Starts stopped jenkins docker containers if they were stopped before. Might fail if jenkins was created not with the script.
* `--restrat` Just shortcut, internally do stop and then start.

# Resources
