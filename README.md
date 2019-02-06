# MetaKube migrations

Scripts for [MetaKube](https://www.syseleven.de/produkte-services/managed-kubernetes/) cluster migrations. If you are not asked to use any of these scripts, you propably don't need to.

## migrate-domain-to-metakube

Script to migrate settings from deprecated k8s.01.syseleven.de domain in MetaKube clusters.

Usage: migrate-domain-to-metakube [-h] [kubeconfig]
Parameters:
  -h|--help: Print this help text.
Positional:
  kubeconfig: Path to kubeconfig for the cluster you want to migrate.

## update-node-passwords

Script to update password settings on each node in a MetaKube cluster.

Usage: update-node-passwords [-kh] [-i identity\_file] [-u user]
Parameters:
  -h|--help : Print this help text.
  -i|--identity identity\_file : Select identity file for SSH connections.
  -k|--no-verify-hostkey : Skip SSH hostkey check.
  -u|--user user : Select username for SSH connections.

## upgrade-cluster

Script to upgrade all nodes of a MetaKube cluster. This will rebuild all machines.

Usage: upgrade-cluster [-ivh] [--os operating_system] [--image image]
Parameters:
  -f|--force: Update all nodes, even if version already correct.
  -h|--help : Print this help text.
  -i|--in-place: Delete old machine(s) first, then add new one(s).
     --image image: Overwrite autodetected image for all nodes. You must also specify the used os.
  -n|--normal: Add new machine(s) first, then delete old one(s).
     --os operating_system: Overwrite autodetected os for all nodes.
  -q|--quiet: Be less verbose
  -v|--verbose: Be more verbose.
