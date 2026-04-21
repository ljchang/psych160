# Psych 160 — Collaborative Projects

A shared workspace for students in **Psych 160** at Dartmouth College to
collaborate on course projects, share code, and develop analyses together.

## Purpose

This repository is a hub for:

- Collaborative development of course projects
- Sharing data analysis code, notebooks, and utilities
- Version-controlled teamwork across student groups
- Peer review and code feedback

## Getting Started

### Clone the repo

```bash
git clone https://github.com/ljchang/psych160.git
cd psych160
```

### Workflow

We use a standard feature-branch workflow:

1. **Create a branch** for your work:
   ```bash
   git checkout -b your-name/short-description
   ```
2. **Commit your changes** with clear messages:
   ```bash
   git add .
   git commit -m "Add analysis of condition X"
   ```
3. **Push your branch** and open a pull request:
   ```bash
   git push -u origin your-name/short-description
   ```
4. **Request review** from a collaborator before merging.

## Repository Structure

Projects are organized under top-level directories (one per project or group).
Keep data small and anonymized — never commit large raw datasets or anything
containing identifying information.

Suggested layout:

```
psych160/
├── project-name/
│   ├── README.md        # what the project does
│   ├── notebooks/       # Jupyter / R notebooks
│   ├── src/             # reusable code
│   └── data/            # small, anonymized data only
└── shared/              # shared utilities across projects
```

## Contributing

- Open an issue or PR rather than pushing directly to `main`.
- Keep commits focused and describe *why*, not just *what*.
- Be kind in reviews — this is a learning environment.

## License

This project is released under the [MIT License](LICENSE).
