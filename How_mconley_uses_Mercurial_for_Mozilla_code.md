How mconley uses Mercurial for Mozilla code

This document tries to capture my common Mercurial (`hg`) use-patterns with Mozilla code. The irony of hosting this on GitHub is not lost on me.

For a (_much!_) more in-depth explanation of how Mercurial works and how to use it with Mozilla code, [please refer to this document](https://mozilla-version-control-tools.readthedocs.io/en/latest/hgmozilla/index.html).

This document is mainly meant to be read from top-to-bottom, but [this section](#problems-and-solutions) has some common problems and solutions in case you're looking for a quick reference.

# Intended audience

I'm writing this primarily for the waves of new contributors I tend to mentor each semester as part of various programs like Outreachy, GSoC, CANOSP, and the MSU Capstone course. This document assumes you're at least somewhat familiar with a DVCS like `git`, but probably haven't used `hg` much beyond maybe cloning a repository.

This document also assumes you're working on either the `mozilla-unified` or `mozilla-central` repositories. Some of what I'm describing might work or make sense for other non-Mozilla projects, but almost certainly there are parts that just won't. So if you've found this page while hunting for a **general guide to using Mercurial**, this is probably not the right choice, and you should keep hunting.

But if you're hoping to hack on `mozilla-unified` or `mozilla-central`, read on.

# `mozilla-central` / `mozilla-unified`

I believe these days, if you follow the [Simple Firefox Build instructions](https://developer.mozilla.org/en-US/docs/Mozilla/Developer_guide/Build_Instructions/Simple_Firefox_build), you end up with a `mozilla-unified` repository. I haven't cloned a fresh repository in a long time, which means that I don't have `mozilla-unified`. My repository is called `mozilla-central`.

`mozilla-unified` is a superset of `mozilla-central` - so it contains it, and more. If you're curious why it exists, [read this](https://mozilla-version-control-tools.readthedocs.io/en/latest/hgmozilla/unifiedrepo.html).

Instead of writing `mozilla-unified` / `mozilla-central` everywhere, I'm just going to use `mozilla-unified` for my own sake. The techniques I describe will work the same in the case of either repository.

# How I tend to do things

Over the years, I've built up a lot of muscle memory in how I use Mercurial. This means that I've tended to do things the same way for many, many years - even as I've learned new techniques. This means that some of the ways I use Mercurial are more verbose than necessary (like [how I move around](#moving-around)), or inconsistently mix `--named` arguments with `-f` flags. This document is not trying to show you the most efficient way to do things - it's trying to document how **I** do things, which is almost certainly not the most efficient. What I can say about my way of doing things is that it seems to work, at least for me.

So maybe it'll work for you, too. `¯\_(ツ)_/¯`

# <a name="my-setup"></a>My Mercurial set-up

In order to do some of the things I describe in this document, you have to have some non-default Mercurial features (extensions) enabled. You do this by [editing your Mercurial "rc" file](https://www.mercurial-scm.org/doc/hgrc.5.html), by using `hg config --edit --local` (for project-wide) or `hg config --edit` (for user-wide).

Find (or add to) a section called `[extensions]`, and add `graphlog=`. So it'll look something like this:

```
# maybe other stuff up here...
# ...

[extensions]
# ... maybe other things listed here
graphlog =
```

This gives you the `hg glog` command, which is the first thing I'm going to mention in [the next section](#glog).

I also use most of the things that `./mach vcs-setup` gives you.

You'll probably want to set those up if you want to use the same `hg` commands I use, in the same way.

I believe by default, Mercurial will use `vi` any time it needs to pop open an editor. If you're not familiar with `vi`, [maybe get familiar with the basics](https://getintodevops.com/blog/how-the-hell-do-i-exit-a-beginners-guide-to-vim) - particularly how to add text, and how to save and quit. Alternatively, [change the default editor to something you're more comfortable with](https://stackoverflow.com/questions/3975164/how-can-i-use-vim-not-vi-to-write-commit-message).

I also generally do not prefer the three-way merge tools like KDiff. Nothing against the authors of those tools or their fans, but I just don't prefer them. I prefer "conflict markers". This means that when Mercurial can't properly merge some changes together, it puts special markers in the file with the sections of code it couldn't merge, and leaves it up to you to sort it out. See [the Conflict resolution](#conflict-resolution) section for details on that.

I choose the conflict markers by adding this setting to the `[ui]` section of the Mercurial "rc" file:

```
merge = internal:merge
```

# <a name="glog"></a>Getting your bearings / knowing where you are

Probably the command I use most often is `hg glog`, which shows a graphical representation of the current state of the tree. I almost reflexively run this command before I do anything else, mainly to verify that my current position in the tree is where I assume it is.

Here is a snippet of what `hg glog` looks like when I use it right now:

```
@  changeset:   598962:6378942bfb04
|  bookmark:    D58273
|  fxtree:      central
|  user:        Emilio Cobos Álvarez <emilio@crisal.io>
|  date:        Wed Jan 08 12:17:07 2020 +0000
|  summary:     Bug 1607557 - Make labels and button inline level. r=Gijs
|
o  changeset:   598961:80ca2534a3e2
|  user:        Brian Grinstead <bgrinstead@mozilla.com>
|  date:        Wed Jan 08 13:15:32 2020 +0000
|  summary:     Bug 1607181 - eagerly set [smoothscroll] on arrowscrollbox instead of waiting for the getter to be called;r=dao
|
o  changeset:   598960:34dd9b331df3
|  user:        pbz <pbz@mozilla.com>
|  date:        Wed Jan 08 12:17:05 2020 +0000
|  summary:     Bug 1591748 - Added test for oa strip permission list. r=Ehsan
|
o  changeset:   598959:9902221ac174
|  user:        pbz <pbz@mozilla.com>
|  date:        Wed Jan 08 13:06:28 2020 +0000
|  summary:     Bug 1591748 - nsPermissionMgr: Added principal oa strip permission list for userContext and privateBrowsing. r=Ehsan
|
<...snip...>
```

So here we see an extremely linear set of revisions. `hg glog` is using the `o` and `|` characters to try to illustrate the relationship between revisions.

There's other useful information in here. Each revision has two primary ways of identifying it - the **revision ID** and the **hash ID**. The revision ID is strictly a number. The **hash ID** is an alphanumeric string. Both IDs are listed here with `hg glog` with a `:` between them. For example, for the tip of `central`, the **revision ID** is `598962` and the **hash ID** is `6378942bfb04`. The **hash ID** is what I tend to use to identify a revision. The reason I prefer the hash ID is because the revision ID is an internal identifier that is not guaranteed to be unique across individual clones of a repository. This means that if I tell a colleague to look at "revision `598962` in their clone of `mozilla-unified`", there's **no guarantee that we'll be looking at the same thing**. However, if I tell that same colleague to look at revision `6378942bfb04` in the same repository, we are almost certainly looking at the same thing.

The `firefoxtree` Mercurial extension from `./mach vcs-setup` is being super helpful, and has marked one of the revisions as `central` (it's the second one from the top). This means that this is the tip of the `mozilla-central` part of the `mozilla-unified` repository in my local clone.

Notice the position of the `@` symbol along the column of `|` characters. The `@` symbol indicates which revision I currently have checked out.

So this tells me that I have the tip of `central` (`mozilla-central`) checked out.

It's important to realize how `hg glog` (and `hg log`, for that matter) orders things. It always orders the revisions it lists with the most recently created one on the top, and the oldest one is at the bottom. So when you create a new commit, it will appear on top, even if its parent is further down the graph.

# <a name="moving-around"></a>Moving around

You can change where you are in the `hg glog` by using `hg update`. For example, if I wanted to check out `80ca2534a3e2`, I'd do:

```
hg update -r 80ca2534a3e2
```

# Committing a new revision

Let's suppose I've done some work in the repository, and it's reached a point where I feel like I want to post it for review. I'll start by creating that revision locally with the `commit` command.

*Note: Unlike `git`, it's perfectly acceptable to `commit` on the tip of what might be considered the `master` branch.*

I'm going to create a revision directly on top of `central`, by typing this:

```
hg commit -m "Bug 6543210 - Distribute cloud jobs across turbo encabulator flux manifold. r?polkaroo."
```

Mercurial is going to look at all of the changes in the working directory for tracked files, and it will create a new revision for them.

Now if I do `hg glog`, I see this:

```
@  changeset:   598964:f37100a3d4c1
|  tag:         tip
|  parent:      598962:6378942bfb04
|  user:        Mike Conley <mconley@mozilla.com>
|  date:        Sun Jan 12 16:35:56 2020 -0500
|  summary:     Bug 6543210 - Distribute cloud jobs across turbo encabulator flux manifold. r?polkaroo.
|
o  changeset:   598962:6378942bfb04
|  bookmark:    D58273
|  fxtree:      central
|  user:        Emilio Cobos Álvarez <emilio@crisal.io>
|  date:        Wed Jan 08 12:17:07 2020 +0000
|  summary:     Bug 1607557 - Make labels and button inline level. r=Gijs
|
o  changeset:   598961:80ca2534a3e2
|  user:        Brian Grinstead <bgrinstead@mozilla.com>
|  date:        Wed Jan 08 13:15:32 2020 +0000
|  summary:     Bug 1607181 - eagerly set [smoothscroll] on arrowscrollbox instead of waiting for the getter to be called;r=dao
|
o  changeset:   598960:34dd9b331df3
|  user:        pbz <pbz@mozilla.com>
|  date:        Wed Jan 08 12:17:05 2020 +0000
|  summary:     Bug 1591748 - Added test for oa strip permission list. r=Ehsan
|
o  changeset:   598959:9902221ac174
|  user:        pbz <pbz@mozilla.com>
|  date:        Wed Jan 08 13:06:28 2020 +0000
|  summary:     Bug 1591748 - nsPermissionMgr: Added principal oa strip permission list for userContext and privateBrowsing. r=Ehsan
|
<...snip...>
```

So the `@` moved automatically for us - the working directory is currently in the state of the `f37100a3d4c1` revision.

# "Whoops, I forgot to add a file"

If we add a new to the codebase, we have to explicitly tell Mercurial that it's a file that's worth caring about and adding. We do this with the `hg add` command.

*Note: Unlike `git`, the `hg add` command is not for adding a file to some kind of staging area for a commit. Mercurial has no notion of a staging area.*

Let's say I added a new file at `browser/locales/en-US/browser/turboEncabulator.ftl`, but forgot to add it in the previous commit I made.

I'd like to correct that. First, in order for Mercurial to know that this is worth paying attention to, I add it like this:

```
hg add browser/locales/en-US/browser/turboEncabulator.ftl
```

Then, I tell Mercurial to fold that change into the most recent commit that I made:

```
hg amend
```

Done! The commit has been updated so that it contains the new file. Let's see what `hg glog` looks like now:

```
@  changeset:   598965:0670bb9bcd68
|  tag:         tip
|  parent:      598962:6378942bfb04
|  user:        Mike Conley <mconley@mozilla.com>
|  date:        Sun Jan 12 16:35:56 2020 -0500
|  summary:     Bug 6543210 - Distribute cloud jobs across turbo encabulator flux manifold. r?polkaroo.
|
o  changeset:   598962:6378942bfb04
|  bookmark:    D58273
|  fxtree:      central
|  user:        Emilio Cobos Álvarez <emilio@crisal.io>
|  date:        Wed Jan 08 12:17:07 2020 +0000
|  summary:     Bug 1607557 - Make labels and button inline level. r=Gijs
|
o  changeset:   598961:80ca2534a3e2
|  user:        Brian Grinstead <bgrinstead@mozilla.com>
|  date:        Wed Jan 08 13:15:32 2020 +0000
|  summary:     Bug 1607181 - eagerly set [smoothscroll] on arrowscrollbox instead of waiting for the getter to be called;r=dao
|
o  changeset:   598960:34dd9b331df3
|  user:        pbz <pbz@mozilla.com>
|  date:        Wed Jan 08 12:17:05 2020 +0000
|  summary:     Bug 1591748 - Added test for oa strip permission list. r=Ehsan
|
o  changeset:   598959:9902221ac174
|  user:        pbz <pbz@mozilla.com>
|  date:        Wed Jan 08 13:06:28 2020 +0000
|  summary:     Bug 1591748 - nsPermissionMgr: Added principal oa strip permission list for userContext and privateBrowsing. r=Ehsan
|
<...snip...>
```

Did you notice that the revision hash ID changed? It was `f37100a3d4c1`, and now it's `0670bb9bcd68`! This is because we modified the revision, and a hash uniquely identifies a revision. Since the revision changed, the hash had to change as well.

# Making amends

`hg amend` is used to fold changes into the most recent commit that you made. I use `hg amend` all of the time - especially to fold in alterations after some review feedback. `hg amend` doesn't take any other arguments and just exits silently when it's done.

Suppose, however, that we wanted to amend, and also change the commit message a little bit. In that case, we could have done:

```
hg commit --amend
```

This command is like `hg amend`, except that it gives you the opportunity to update the commit message. It will open the default editor and let you update the commit message.

Alternatively, you can do it all at once like this:

```
hg commit --amend -m "Bug 6543210 - Distribute MORE cloud jobs across turbo encabulator flux manifold. r?polkaroo."
```

## Caveats

You are only allowed to amend revisions that you have not pulled from `central`. If you pulled the revision from `central`, then it's there to stay, and cannot be changed. This goes for most kinds of history rewriting: Mercurial will actively prevent you from trying to rewrite the history of revisions that have been shared with a public repository like `mozilla-unified`. Curious why? [Read this](https://book.mercurial-scm.org/read/changing-history.html#why-avoid-changing-history).

# Removing a file

Suppose part of my change is also supposed to remove a file called `browser/locales/en-US/chrome/browser/turboEncabulator.dtd` from the source tree. Like adding a file, we need to explicitly tell Mercurial that we're intentionally removing that file. We do this like so:

```
hg remove browser/locales/en-US/chrome/browser/turboEncabulator.dtd
```

Mercurial will also take care of actually removing the file from the file system.

# What changes have I made?

You can see the state of your working directory using `hg status`. If I edited a file called `browser_selectpopup.js`, I might see something like this:

```
M browser/base/content/test/forms/browser_selectpopup.js
```

The `M` indicates that the file at `browser/base/content/test/forms/browser_selectpopup.js` has uncommitted modifications.

I can use `hg revert` to undo those changes if I'd like:

```
hg revert browser/base/content/test/forms/browser_selectpopup.js
```

This will put `browser_selectpopup.js` back into the state it was in before I made any modifications. **Careful with revert**, this is a great way to lose work that you actually meant to save!

# Keeping my tree up-to-date

Over time, my pull of `mozilla-unified` will slowly fall behind as more and more revisions land on the main repository from other people. Let's take a look at `hg glog` again:

```
@  changeset:   598965:0670bb9bcd68
|  tag:         tip
|  parent:      598962:6378942bfb04
|  user:        Mike Conley <mconley@mozilla.com>
|  date:        Sun Jan 12 16:35:56 2020 -0500
|  summary:     Bug 6543210 - Distribute cloud jobs across turbo encabulator flux manifold. r?polkaroo.
|
o  changeset:   598962:6378942bfb04
|  bookmark:    D58273
|  fxtree:      central
|  user:        Emilio Cobos Álvarez <emilio@crisal.io>
|  date:        Wed Jan 08 12:17:07 2020 +0000
|  summary:     Bug 1607557 - Make labels and button inline level. r=Gijs
|
o  changeset:   598961:80ca2534a3e2
|  user:        Brian Grinstead <bgrinstead@mozilla.com>
|  date:        Wed Jan 08 13:15:32 2020 +0000
|  summary:     Bug 1607181 - eagerly set [smoothscroll] on arrowscrollbox instead of waiting for the getter to be called;r=dao
|
o  changeset:   598960:34dd9b331df3
|  user:        pbz <pbz@mozilla.com>
|  date:        Wed Jan 08 12:17:05 2020 +0000
|  summary:     Bug 1591748 - Added test for oa strip permission list. r=Ehsan
|
o  changeset:   598959:9902221ac174
|  user:        pbz <pbz@mozilla.com>
|  date:        Wed Jan 08 13:06:28 2020 +0000
|  summary:     Bug 1591748 - nsPermissionMgr: Added principal oa strip permission list for userContext and privateBrowsing. r=Ehsan
|
<...snip...>
```

Okay, I'm where I expect, and `hg status` doesn't list any uncommitted modifications. This means I can try to pull the most recent changes from `central` over the network. We do this with `hg pull`.

This will pull the new changes now and add them to your tree, so your `hg glog` is going to change. Plus, the `firefoxtree` is going to update things so that `central` refers to the most recent tip of `mozilla-central` that you're pulling down.

What's more, what I normally do is try to simultaneously **rebase** my local changes on top of the most recent commit once I have it. I do that with the `--rebase` argument, like so:

```
hg pull central --rebase
```

This is telling Mercurial: "Please pull down the most recent changes from `mozilla-central`, then take the line of commits between my original `central` revision, and replay them on the new `central`".

Let's see what happened when I ran that command:

```
$ hg pull central --rebase
pulling from central
searching for changes
adding changesets
adding manifests
adding file changes
added 13 pushes
added 536 changesets with 3031 changes to 2094 files (+1 heads)
new changesets a2c5a0150d9f:1536cf66a302
rebasing 598965:0670bb9bcd68 "Bug 6543210 - Distribute cloud jobs across turbo encabulator flux manifold. r?polkaroo."
```

Mercurial is saying that it pulled 536 revisions down, and then was able to successfully rebase my one change on top of the new `central`. Hooray! I'm good to go.

Sometimes, if you're working on the same file as someone else, Mercurial won't be able to do a rebase automatically, and so you'll need to do manual conflict resolution. See [the Conflict resolution](#conflict-resolution) section for details on that.

## Handy tip - going from your current, local `central` to the most up-to-date `central`

If you have `central` checked out locally, and no uncommitted changes, typing this:

```
hg pull central -u
```

will pull the latest revisions from `central` and update your current position to the tip of it in one move.

# Rebasing revisions

Sometimes you want to manually move one or more revisions around in the tree. You do this with the `rebase` command.

Under the hood, Mercurial isn't actually _moving_ these revisions. It's creating new revisions and then hiding the old ones in the graph. This means that if you somehow get into a bad state with your rebase (or even after your rebase), your old committed work will still be in the tree as hidden revisions. You can view them with `hg glog --hidden`. [See this section on how to bring hidden revisions back to life](#bring-back-hidden-revisions).

Suppose I want to rebase a revision `a316e957c675` so that it's parent is `central`. I would do that like this:

```
hg rebase -r a316e957c675 --dest central
```

I could have also passed in another revision hash as the destination in case I wanted to rebase on something that wasn't the tip of `central`:

```
hg rebase -r a316e957c675 --dest f1956487f00c
```

Presuming these are local revisions that can be mutated (remember, we can't change revisions that we've pulled down from `central`).

## Rebasing multiple revisions

If you're being fancy, maybe you've got multiple revisions all stacked on top of one another that you want to move as a unit.

Suppose that the revision hash for the earliest revision in that set of revisions is `79c795b22f1a`, and the revision has for the last revision in that set of revisions is `32d6e8a34f39`. Suppose we want to rebase them to `central`.

In that case, you can do this:

```
hg rebase -r 79c795b22f1a::32d6e8a34f39 --dest central
```

Note the double-colon between the revision IDs - `::` ! **That's important.**

# Getting rid of ("pruning") revisions

Sometimes you accumulate revisions that you don't want to worry about anymore. Maybe you used `moz-phab patch` to apply a patch to test and you're done your testing. Suppose it has the revision hash `49fcf58f9866`.

You can prune that revision like so:

```
hg prune -r 49fcf58f9866
```

Like rebasing, you can prune a set of revisions like so:

```
hg prune -r 79c795b22f1a::32d6e8a34f39
```

Pruned revisions are not deleted. They're hidden in the graph. This means that if you accidentally prune a revision and want it back, [you can do that](#bring-back-hidden-revisions).

# Squashing / folding / pruning / reordering multiple revisions with `histedit`

We've started to get fancy and talk about dealing with multiple revisions all at once. You might get into this situation if you ended up using `hg commit` a lot instead of `hg amend` to address review feedback.

The `histedit` command lets us specify a range of local revisions to change (remember, we can't change things we've pulled from `central` - it won't let you), and then will open up a `curses` ("text-based terminal") interface for you to express what to do with each of the revisions in one shot.

Like with `rebase`, we supply `histedit` with the starting and ending revision hashes for the set of revisions we're trying to modify. Suppose we want to modify the revisions between `79c795b22f1a` and `32d6e8a34f39` (including those revisions), we'd use:

```
hg histedit -r 79c795b22f1a::32d6e8a34f39
```

and this will attempt to open the `curses` interface for you to use.

## Getting `curses` working on Windows

The MozillaBuild thing that Windows hackers use doesn't ship with the ability to do the `curses` stuff that `histedit` requires, so you might see an error when first using `histedit` like `abort: No module named _curses`. Thankfully, someone wrote a Python package to give you that capability. You can install it with `pip install windows-curses`.

## Using `curses` interface for `histedit`

You should see a list of revisions in the `curses` UI, with the words `pick` next to each one. You can use the up and down cursor keys on your keyboard to highlight different revisions, and you can see the revision details at the bottom.

Perhaps unintuitively (since it's the opposite of how `hg glog` works), the revisions are listed top to bottom from oldest to newest.

From here, we can choose to do different things with each revision. The menu at the top tells you what your options are. You can reorder the patches using `Shift-j` and `Shift-k`. You can view the patch with `v` (and then hit `v` again to exit that view).

At any time, you can bail out by pressing `q`, and you'll exit back to your terminal without changing anything.

### Press `d` to `drop` a revision

Drop lets you get rid of a revision in a series. Like with `rebase`, the old series is just hidden in the `hg glog` graph, [so the dropped revision can be revived if need be](#bring-back-hidden-revisions).

### Press `e` to `edit` a revision

I don't use this option, and can't really comment on what it does or how it works.

### Press `f` to `fold` a revision into its parent revision

I use this if I have fix-ups that I want to fold into the previous revision. It will merge the two revisions together. This is like `roll`, except that once you exit the `curses` interface, you'll be asked to edit the commit message of the new merged revision (the editor will show both revision's commit messages).

### Press `m` to `mess` (update the commit message for a revision)

You might want to update a commit message to make it clearer, or to fix a mistake in it. Once you exit the `curses` interface, the editor will open letting you update the commit message of that revision.

### Press `p` to `pick` (which means to leave the revision alone)

This is the default state, and means to leave the revision as-is.

### Press `r` to `roll` a revision into its parent revision

This is just like `fold`, but it will just use the parent revision commit message instead of asking you to resolve the two merged commit messages. Really handy if the revision you're rolling is a minor fix-up with a commit message like, `Fixing my mistake, lol`.

If it's not immediately obvious, this interface lets you manipulate one or more of the listed revisions. When you've expressed what you want to do, hit `c`. The `curses` editor will exit, and the default editor might open up a few times to let you do things like update commit messages.

Note that reordering revisions might result in conflicts. See [Conflict resolution](#conflict-resolution).

# <a name="conflict-resolution"></a>Conflict resolution

I'll be honest, this always feels like the scariest part of version control to me. I'll briefly explain what a conflict is, and then I'll describe how I got about resolving them.

Suppose you're working on a file, `browser/base/content/browser.js`. You've modified some functions, and things are going well. However, it's been a while since you've last pulled from `central`, and you want a more up-to-date tree. So, with your revision checked out and no uncommitted work, you use `hg pull central --rebase` to rebase onto the most recent tip of `central`.

But there's a problem! Earlier that day, someone else landed a revision to `browser/base/content/browser.js` that changed some of the lines of the functions you were touching - things that your change was originally based on. You've pulled that revision, and Mercurial attempts to apply your change on to with the rebase. Unfortunately, in this case, Mercurial isn't smart enough to resolve the discrepency, and throws up its hands and complains about conflicts. This complaint looks like this:

```
warning: conflicts while merging browser/base/content/browser.js! (edit, then use 'hg resolve --mark')
```

At this point, Mercurial stops whatever its doing and drops you back into your terminal.

The first thing to realize is that Mercurial has *paused the rebase* in order to wait for you resolve the conflict. The rebase is still underway, and you either have to resolve the conflict and continue it, or you can abort it.

To abort a rebase, you can use:

```
hg rebase --abort
```

The changes that you pulled down will still be in your tree, but the revision that Mercurial tried to rebase will be right where you left it, unchanged. I've done this before when I've felt like the conflict was just too nasty to resolve by hand, and that it was ultimately easier to just re-implement the revision manually on top of the new changes.

In my experience though, it's rare to need to give up a rebase due to conflicts. So we'll try to resolve it within the conflicted file. Since [Mercurial was configured](#my-setup) to use conflict markers, each conflicted file (there's only one in my example here, but there might be several) will have some text in them for you to deal with.

In particular, you're looking for `<<<<<<<`, `=======` and `>>>>>>>` strings. These strings are the conflict markers that represent where Mercurial had trouble. You'll see something like this:


```
// This is a contrived example, purely for illustration
function mySpecialFunction() {
  console.log("Running mySpecialFunction!");
<<<<<<< local
  console.log("I'm sure glad we're using version control!");
=======
  console.log("I'm a new line of text that someone added recently.");
>>>>>>> other
  return true;
}
```

So what happened here is that I was adding a new line to this function, `console.log("I'm sure glad we're using version control!");`, but in my recent pull, someone else had added a `console.log("I'm a new line of text that someone added recently.");`, and Mercurial doesn't know if it's supposed to overwrite that `console.log`, or put one after the other.

So in this case, `local` is showing us what we were *originally doing in this function*, and `other` is showing us *what Mercurial failed to apply the changes on top of*.

Now that I see the state of things, what I think I want to do is combine the two strings into a single `console.log`. So I update the file in my editor to look like this:

```
// This is a contrived example, purely for illustration
function mySpecialFunction() {
  console.log("Running mySpecialFunction!");
  console.log("I'm a new line of text that someone added recently. Also, " +
              "I'm sure glad we're using version control!");
  return true;
}
```

Notice that I removed the conflict markers. This is important - I've put the file into the state that I think is appropriate. That's all you need to do.

I check around the rest of the file, and I don't see any more conflict markers, so it's time to mark the conflict as resolved.

## Marking conflicts as resolved

I'm just going to double-check that I don't have any other files to resolve conflicts in. I use `hg status`, like this:

```
$ hg status

M browser/base/content/browser.js
# The repository is in an unfinished *rebase* state.

# Unresolved merge conflicts:
#
#     browser/base/content/browser.js
#
# To mark files as resolved:  hg resolve --mark FILE

# To continue:    hg rebase --continue
# To abort:       hg rebase --abort
```

So it was just the one file. In order for Mercurial to know that it's safe to continue the rebase, I mark the conflict as resolved, like this:


```
hg resolve --mark browser/base/content/browser.js
```

and then I continue the rebase, like this:

```
hg rebase --continue
```

Having done this, Mercurial will continue to apply any changes that still need to be rebased. This might mean additional conflicts that need to be resolved, so deal with them as they come. Eventually, however, the rebase will complete, and you'll be good to go!

When dealing with conflict resolution like this, it's easy for mistakes or new bugs to creep in because the underlying code changed on you. It's usually a good idea to do a new round of testing after you do a rebase like this.

So that's how I do conflict resolution. If you're interested in reading more examples, you can [find some in the official Mercurial tutorial](https://www.mercurial-scm.org/wiki/TutorialConflict).

# <a name="problems-and-solutions"></a>Problems and how to solve them

## A file in the working directory accidentally got deleted! How do I get it back?

Suppose you accidentally deleted a file called `turboEncabulator.dtd` like this:

```
rm -rf browser/locales/en-US/chrome/browser/turboEncabulator.dtd
```

And now `hg status` is showing you `!` for that file because it's gone missing.

Whoops! Thankfully, since Mercurial was tracking this file, we can recover it, like so:

```
hg revert browser/locales/en-US/chrome/browser/turboEncabulator.dtd
```

This will bring the file back, just as it always was for the revision that you currently have checked out.

## I can't see the "@" in `hg glog`! Where am I?

If you pull from `central`, and choose not to `--rebase`, like this:

```
hg pull central
```

a bunch of revisions will get added to your tree, but your position in the tree will not change.

This might push the `@` indicating your current position out of the first few pages of the `hg glog` output. There are two things you can do:

### Use `hg wip`

`hg wip` will show a compressed version of the tree, only including the changes that you've been working on. That might help you see where you are.

### <a name="searching-for-here"></a>Finding the `@` marker

`hg glog` is running your shell inside something like `less`, which lets you search the text for a search string. Like in `less`, you start a search with the (rather unintuitive) forward slash (`/`) on the keyboard. Then type in your search string and press enter.

So to find `@`, inside the `hg glog` view, you'd do:

`/ @`

And press `Enter`. Notice that space before the `@`? That's key - that's going to prevent you from accidentally hitting search results for all of the email addresses in the tree.

You _might_ match a commit message that has an `@` character in it, in which case, hit `Enter` again to keep searching.

Your current position might be way, way down in the `hg glog` graph, but it'll be there. Rest-assured, you are _somewhere_ in the graph.

## <a name="bring-back-hidden-revisions"></a>I have hidden revisions that I want to bring back

Suppose you have a revision that is hidden, and you want to get its changes back. Mercurial won't let you just remove the `hidden` state from it. Instead, it'll recreate the revision with the exact same parent revision, and the exact same file changes, but the revision hash will be different.

To revive the hidden revision `32d6e8a34f39`, we use the command `touch`, like this:

```
hg touch -r 32d6e8a34f39
```

Using `hg glog`, you'll see that a new revision has been created with the same commit message and the same file changes as the original `32d6e8a34f39` revision - but it has a new hash.

## How do I see the contents of a revision?

Suppose you want to see the contents of revision `a316e957c675`. You'd do that with:

```
hg export -r a316e957c675
```

This shows a read-only view of the revision. You can use the up and down keyboard cursors to move the view up and down, or Page Up / Page Down to move more quickly. You can use `/` [like in this earlier tip](#searching-for-here) to search the revision contents. Pressing `q` will exit the view.

You can also write the contents of that revision to a file `bug.diff` (or `my-patch.diff` or whatever), with:

```
hg export -r a316e957c675 > bug.diff
```

# Thanks

I want to thank all of the students who've worked with me over the years, and let me guide them through the wild and wacky world of hacking on Mozilla code with Mercurial. I've learned a lot.

