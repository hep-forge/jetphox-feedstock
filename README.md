# jetphox-feedstock

[![hep-forge](https://img.shields.io/badge/package-hep--forge%2Fjetphox-orange.svg)](https://anaconda.org/hep-forge/jetphox)
[![Build & Upload](https://github.com/hep-forge/jetphox-feedstock/actions/workflows/autoupload.yml/badge.svg)](https://github.com/hep-forge/jetphox-feedstock/actions/workflows/autoupload.yml)
[![Anaconda Version](https://anaconda.org/hep-forge/jetphox/badges/version.svg)](https://anaconda.org/hep-forge/jetphox)
[![Anaconda Platforms](https://anaconda.org/hep-forge/jetphox/badges/platforms.svg)](https://anaconda.org/hep-forge/jetphox)

Feedstock for [JETPHOX](https://lapth.cnrs.fr/PHOX_FAMILY/jetphox.html) — part of [hep-forge](https://anaconda.org/hep-forge).
Builds linux-amd64 + linux-arm64 in one matrix workflow and uploads to the
[hep-forge](https://anaconda.org/hep-forge) Anaconda channel.

JETPHOX: NLO cross sections for prompt photon (direct + fragmentation) and
hadron production, inclusive or isolated, with or without a jet
(P. Aurenche, M. Fontannaz, J.-Ph. Guillet, E. Pilon, M. Werlen et al., LAPTH).

## Usage

JETPHOX builds a run-specific executable from its parameter files, so the
package ships the source tree with the run-independent libraries (BASES,
fragmentation functions, nuclear PDFs) pre-built:

```bash
jetphox-init myrun                 # copy a ready-to-run tree (LHAPDF path set to this env)
cd myrun/working
$EDITOR parameter.indat            # process, energies, PDF, scales, isolation, cuts
perl start.pl                      # generates the code and compiles run<name>.exe
./run<name>.exe                    # see Readme_jetphox.html
```

Versions: upstream `1.3.1_4` is published as `1.3.1.4` (conda versions cannot
carry the `_` suffix).

## Install

```bash
conda install -c hep-forge -c conda-forge jetphox
```

## Maintainers

* [@meiyasan](https://github.com/meiyasan/)
