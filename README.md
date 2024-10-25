# User and Group Management with ACL

**Authors : [@RubnK](https://github.com/RubnK), [@yayou05](https://github.com/yayou05) & [@len233](https://github.com/len233)**

This Bash script automates user and group management on a Linux system. It simplifies the process of adding users, managing inactive accounts, and configuring Access Control Lists (ACL) for shared directories.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Configuration](#configuration)
- [Features](#features)
- [Parameters](#parameters)
- [Contributing](#contributing)

## Prerequisites
To use this script, you will need:
- Access to a Linux environment with superuser (sudo) privileges.
- Basic understanding of Bash scripting and Linux user management.

## Setup
1. Clone or download this repository to your local machine.
2. Ensure that ACL is installed on your system by running:
   ```bash
   sudo apt-get install acl

3. Create a file named users.txt containing the users to add, formatted as follows:

<username> <group_name> <shell> <home_directory>


4. Run the script with superuser rights:

```bash
sudo ./script.sh
```



## Configuration

To configure parameters such as inactive days and backup directory, modify the relevant variables at the beginning of the script. For example:
```bash
inactive_days=90           # Number of days of inactivity to consider a user as inactive
backup_dir='/backup_users' # Directory where deleted user data will be backed up
shared_dirs=('/shared_dir1' '/shared_dir2') # List of directories for ACL configuration
```

## Features

Automatically creates users and groups based on the users.txt input file.

Identifies and manages inactive users based on a configurable threshold.

Provides options to lock, delete, or ignore inactive users.

Backs up personal directories of deleted users to a specified location.

Removes empty groups automatically, ensuring a clean user environment.

Applies ACL permissions on specified shared directories for enhanced security.


## Parameters

**users.txt**: A file containing user details formatted as <username> <group_name> <shell> <home_directory>.

**inactive_days**: The number of days after which a user is considered inactive (default: 90 days).

**backup_dir**: The directory for backing up deleted user data (default: /backup_users).

**shared_dirs**: A list of directories where ACL permissions will be set.


## Contributing

Feel free to contribute to the project by submitting issues or pull requests.
