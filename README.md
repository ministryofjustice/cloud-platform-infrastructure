# Kubernetes Investigations

A space to collect code related to the cloud platform team's Kubernetes investigations.

As we complete spikes or investigations into how we want to run Kubernetes we can collect useful code that we have written here so that it is available to the team.

We will also document some of the thinking behind how the code is written so that it is available to people who are new to the team or ourselves when we forget why we are doing it.

## How to add your examples

Generally speaking, follow the Ministry of Justice's [GitHub good practice]().

### 1. Clone the repo

```
git clone git@github.com:ministryofjustice/kubernetes-investigations.git
```

### 2. Create a branch

For example:

```
git checkout -b spike/monitoring-investigation
```

I used `spike/monitoring-investigation` as an example of a pattern for branch names. You can come up with your own branch name that matches the pattern (e.g. `feature/a-new-monitoring-stack` or `idea/deploy-using-bash-scripts`).

### 3. Add your work to the branch

Think about where to put it &mdash; perhaps in a directory with a useful name (e.g. "prometheus") and collect together similar things (e.g. put "prometheus" directory under a "monitoring" directory).

### 4. Commit your code

Write a commit message that might be useful for people who come to the code to find out what it is for. This might be helpful: [How to write a git commit message](https://chris.beams.io/posts/git-commit/).

Here's an example:

```
Added contributing instructions

I added some instructions to the repo in a README file so that
other members of the team would know how to add code to the repo.

I aimed to make the instructions clear and simple to follow. I also
wanted to make sure that people left good context for the contributions
that they were making, so I added quite a lot about commit messages.
```

### 5. Raise a pull request

Raise a pull request by pushing your branch to the GitHub:

```
git push origin master spike/monitoring-investigation
```

and then navigating to the repo in GitHub and using the create a new pull request button.

When you do this you have the option of adding a reviewer. It's good to share your pull request for review so add a reviewer. Let the reviewer know that you are adding them so they have a chance to plan some time to do the review.

If you can't find anyone add Kerin or Kalbir.

### 6. *Optional* Add some information to the confluence docs

If there is more information that you think would be useful add it into confluence in our Kubernetes section (sorry for those of you reading this outside of our team).
