# Managing DartFS ACL Permissions

A practical guide for adding/removing users on shared lab directories in DartFS HPC storage (`/dartfs-hpc/...`).

DartFS uses **NFSv4 ACLs**, not POSIX ACLs. This means `setfacl`/`getfacl` (the POSIX tools) will not work as expected — you must use `nfs4_setfacl` and `nfs4_getfacl`.

---

## TL;DR — Add one user to a directory

```bash
DIR=/dartfs-hpc/rc/home/v/f00275v/cosanlab
USER=f006jkw

# 1. Grant access to the directory itself
nfs4_setfacl -a "A::${USER}@KIEWIT.DARTMOUTH.EDU:rwaDxtTnNcy" "$DIR"

# 2. Make NEW files/dirs created inside inherit the same access
nfs4_setfacl -a "A:fd:${USER}@KIEWIT.DARTMOUTH.EDU:rwaDxtTnNcy" "$DIR"

# 3. (Optional) Apply to EXISTING files/dirs inside — see caveats below
nfs4_setfacl -R -a "A::${USER}@KIEWIT.DARTMOUTH.EDU:rwaDxtTnNcy" "$DIR"
```

Verify with:

```bash
nfs4_getfacl "$DIR"
```

---

## Anatomy of an ACE (Access Control Entry)

Each line in an NFSv4 ACL has four fields separated by colons:

```
A : fd : f006jkw@KIEWIT.DARTMOUTH.EDU : rwaDxtTnNcy
│   │            │                           │
│   │            │                           └── permission letters
│   │            └── principal (user or group + realm)
│   └── flags (inheritance, group marker, etc.) — may be empty
└── type: A = Allow, D = Deny
```

### Type

- `A` — **Allow** (the common case)
- `D` — **Deny** (rare; use with care — deny entries take precedence)

### Flags

| Flag | Meaning |
|------|---------|
| *(empty)* | Applies only to this object |
| `f` | Inherited by new **files** created inside a directory |
| `d` | Inherited by new **directories** created inside a directory |
| `fd` | Both of the above — the usual choice for shared lab dirs |
| `g` | Principal is a **group**, not a user |
| `i` | Inherit-only (doesn't apply to the dir itself, only propagates) |

### Principal

Always use the fully-qualified form: `netid@KIEWIT.DARTMOUTH.EDU`. The realm suffix is required on DartFS — omitting it will silently map to `nobody`.

For groups, add the `g` flag and use the group name: `A:g:rc-cosanlab@KIEWIT.DARTMOUTH.EDU:...`.

### Permission letters

| Letter | On files | On directories |
|--------|----------|----------------|
| `r` | Read data | List contents |
| `w` | Write/modify data | Create files in dir |
| `a` | Append data | Create subdirs |
| `x` | Execute | Traverse (cd into) |
| `D` | — | Delete child objects |
| `d` | Delete this file | Delete this dir |
| `t` | Read attributes (size, mtime, …) | same |
| `T` | Write attributes | same |
| `n` | Read named attributes | same |
| `N` | Write named attributes | same |
| `c` | Read ACL | same |
| `C` | **Write ACL** (dangerous — gives user control of perms) | same |
| `o` | Change owner | same |
| `y` | Synchronize (almost always include) | same |

**Common bundles:**

- Read-only: `rxtncy`
- Read/write (standard lab member): `rwaDxtTnNcy`
- Full control (co-owner): `rwaDdxtTnNcCoy`

---

## Common tasks

### View current ACL

```bash
nfs4_getfacl /dartfs-hpc/rc/home/v/f00275v/cosanlab
```

### Add a user with read/write access (with inheritance)

```bash
nfs4_setfacl -a "A::f006jkw@KIEWIT.DARTMOUTH.EDU:rwaDxtTnNcy"   /dartfs-hpc/rc/home/v/f00275v/cosanlab
nfs4_setfacl -a "A:fd:f006jkw@KIEWIT.DARTMOUTH.EDU:rwaDxtTnNcy" /dartfs-hpc/rc/home/v/f00275v/cosanlab
```

### Add a user read-only

```bash
nfs4_setfacl -a "A::f006jkw@KIEWIT.DARTMOUTH.EDU:rxtncy"   /dartfs-hpc/rc/home/v/f00275v/cosanlab
nfs4_setfacl -a "A:fd:f006jkw@KIEWIT.DARTMOUTH.EDU:rxtncy" /dartfs-hpc/rc/home/v/f00275v/cosanlab
```

### Add a whole group

```bash
nfs4_setfacl -a "A:g:rc-cosanlab@KIEWIT.DARTMOUTH.EDU:rwaDxtTnNcy"   /dartfs-hpc/rc/home/v/f00275v/cosanlab
nfs4_setfacl -a "A:fdg:rc-cosanlab@KIEWIT.DARTMOUTH.EDU:rwaDxtTnNcy" /dartfs-hpc/rc/home/v/f00275v/cosanlab
```

Note the `g` flag on both ACEs, and `fdg` combines file/dir inheritance with the group marker.

### Remove a user

```bash
nfs4_setfacl -x "A::f006jkw@KIEWIT.DARTMOUTH.EDU:rwaDxtTnNcy"   /dartfs-hpc/rc/home/v/f00275v/cosanlab
nfs4_setfacl -x "A:fd:f006jkw@KIEWIT.DARTMOUTH.EDU:rwaDxtTnNcy" /dartfs-hpc/rc/home/v/f00275v/cosanlab
```

The ACE being removed must match **exactly** what's in the ACL (type, flags, principal, permissions). Easiest way is to run `nfs4_getfacl` first and copy-paste the line.

### Edit the full ACL in `$EDITOR`

```bash
nfs4_setfacl -e /dartfs-hpc/rc/home/v/f00275v/cosanlab
```

Useful for bulk changes or reordering. Remember: order matters in NFSv4 ACLs — entries are evaluated top-to-bottom, first match wins.

---

## Inheritance vs. recursion — a critical distinction

These do different things:

- **Inheritance (`fd` flag):** A template for **future** files/dirs created inside. Does nothing to what's already there.
- **Recursion (`-R`):** Walks the existing tree and applies an ACE to each object.

You almost always want **both**: inheritance so new content gets the right perms automatically, and a one-time recursive pass to fix up existing content.

### Caveat: recursive changes require ownership

`nfs4_setfacl -R` will fail with `Permission denied` on any file inside the tree that you don't own — even if the top-level directory is yours. This happens in shared lab directories where different users have created files over time.

**Three ways to handle existing files:**

1. **Do nothing.** Only new files will have the right ACL. Old files keep whatever they had. Fine if the lab reorganizes or the new member only works with new data.

2. **Ask file owners to re-apply permissions themselves.** Each owner can run:
   ```bash
   find /dartfs-hpc/rc/home/v/f00275v/cosanlab -user $(whoami) \
     -exec nfs4_setfacl -a "A::f006jkw@KIEWIT.DARTMOUTH.EDU:rwaDxtTnNcy" {} \;
   ```

3. **Escalate to Research Computing.** Email `research.computing@dartmouth.edu` — they can run the recursive change as root across all owners.

---

## Gotchas

- **Always include `y` (synchronize)** in your permission string. Omitting it can cause confusing `Permission denied` errors on some clients.
- **The `@KIEWIT.DARTMOUTH.EDU` realm is mandatory.** A bare NetID silently maps to `nobody`.
- **Order of ACEs matters.** Deny entries should typically come before Allow entries. `nfs4_setfacl -a` appends at the end; use `-A` or `-e` for precise ordering.
- **Group membership is separate from ACLs.** Being in the `rc-cosanlab` AD group (managed by RC) and having an ACL entry on a directory are two different mechanisms. A user can have ACL access without group membership and vice versa.
- **`getfacl` vs `nfs4_getfacl` mismatch.** The POSIX `getfacl` will show the owner/group/other bits but won't show any of the NFSv4 ACEs — you'll miss most of the real permissions. Always use `nfs4_getfacl` on DartFS.
- **Home directories are ACL-managed too.** If you want to share files from `/dartfs-hpc/rc/home/v/<netid>`, the same rules apply — but traversal (`x`) must be granted on every parent directory in the path, or nobody can reach the file.

---

## Worked example — what was done for f006jkw on 2026-04-21

```bash
# Confirm user exists and check their existing groups
id f006jkw

# Grant rw access on the dir + inheritance for future files
nfs4_setfacl -a "A:fd:f006jkw@KIEWIT.DARTMOUTH.EDU:rwaDxtTnNcy" \
  /dartfs-hpc/rc/home/v/f00275v/cosanlab

# (Attempted recursive apply — failed on files owned by others; see caveats)
nfs4_setfacl -R -a "A::f006jkw@KIEWIT.DARTMOUTH.EDU:rwaDxtTnNcy" \
  /dartfs-hpc/rc/home/v/f00275v/cosanlab

# Verify
nfs4_getfacl /dartfs-hpc/rc/home/v/f00275v/cosanlab
```

Resulting ACL on the top-level directory:

```
A::f006jkw@KIEWIT.DARTMOUTH.EDU:rwaDxtTnNcy
A:fd:f006jkw@KIEWIT.DARTMOUTH.EDU:rwaDxtTnNcy
A::OWNER@:rwaDdxtTnNcCoy
A::GROUP@:rwaDxtTnNcy
A::EVERYONE@:rxtncy
```

---

## References

- `man nfs4_acl` — permission letter reference
- `man nfs4_setfacl` — full flag documentation
- Dartmouth RC docs: <https://rc.dartmouth.edu/index.php/dartfs/>
- RC support: `research.computing@dartmouth.edu`
