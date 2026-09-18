# CPEE-HISTORY

A history service for the cloud process execution engine (cpee.org), built
with [riddl](https://github.com/etm/riddl). It receives change events from
the engine and stores description, dataelements, endpoints and attributes of
every instance in a git repository, so that older versions can be retrieved.

Resources:

```
POST /                                             # engine event stream (type, topic, event, notification)
GET  /instances                                    # list of instance uuids
GET  /instances/{uuid}/commits                     # commits of an instance
GET  /instances/{uuid}/commits/{commit}/description
GET  /instances/{uuid}/commits/{commit}/dataelements
GET  /instances/{uuid}/commits/{commit}/endpoints
GET  /instances/{uuid}/commits/{commit}/attributes
GET  /instances/{uuid}/commits/{commit}/testset    # complete testset of that commit
```

## Installation

* gem install cpee-history

## Scaffold a local install

* cd ~/run
* cpee-history new hist

## Configuration

The `hist.conf` (YAML) sits next to the `hist` daemon script and is loaded
automatically on startup:

```yaml
:history_dir: history
```

* `history_dir` — directory (relative to the daemon script) holding the git
  repository with the instance histories. Defaults to `history`.

Options can also be overridden on the command line:

```
./hist -o port=9318 -o history_dir=history -v start
```
