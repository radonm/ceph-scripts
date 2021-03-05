# Script to install ceph on 1 node(physical or VM)
## Required
* **Ubuntu 20+ is tested**
* **Server must have 2 H(V)DDs - one for the operating system and one for ceph storage.**
* **Before running the script make sure second block device is cleared - no existing partitions or LVM sigantures. If script complains hdd is not empty use wipefs to clear it and run it again.**
* **Passwordless sudo for the account running the script**

## General information
* Do not use if there are old (half)working ceph installation attempts, wipe clean and reinstall OS first.
* Install time can be greatly reduced if you run os update procedure in advance.

* Copy and paste code blocks below


## Ubuntu 20+
```git clone https://github.com/radonm/ceph-scripts;./ceph-scripts/Ubuntu/Install1NodeCeph.sh```
