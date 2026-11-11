#! /usr/bin/bash
set -euo pipefail

# JETPHOX has no install step: `perl start.pl` (in working/) generates the
# histogram code, rewrites working/Makefile and compiles a run-specific
# executable, writing into the source tree itself (src/histo/perlmod). The
# package therefore installs the whole tree under share/jetphox and a
# jetphox-init command that copies it into a writable working directory.
# Only the run-independent libraries are compiled here; start.pl skips
# them when libbases.a / libfrag.a / libpdfa.a already exist.

# Fortran 77 sources written for g77/DEC f77: modern gfortran rejects the
# argument-type mismatches and BOZ constants unless told otherwise, and
# -std=legacy is needed for frag/dss/fDSS.f, which passes 2-element arrays to
# FINT's 5-element dummies (CERNLIB interpolation, reads only NARG entries):
# gfortran >= 10 makes that a hard "too few elements" error otherwise.
LEGACY="-std=legacy -fallow-argument-mismatch -fallow-invalid-boz -w"

# ---- working/Makefile: point it at the conda toolchain and libraries --------
# Upstream hardcodes LAPP paths (PATHLHAPDF, ROOTCONFIG) and gcc 4.4 library
# directories. PATHLHAPDF keeps its "PATHLHAPDF\t= <path>" form because
# start.pl rewrites that line from parameter.indat's lhapdf_path.
M=working/Makefile
# the C++ runtime run*.exe links: libc++ on macOS (libstdc++ there is GCC's,
# from gfortran, and must not load next to clang's libc++)
# and the C++ compiler for the ROOT histogram code: on macOS ROOT's headers
# are libc++'s, which only clang reads (the g++ there is gfortran's GCC)
CXXRT=-lstdc++
RUNCXX=g++
if [[ "$(uname)" == "Darwin" ]]; then
  CXXRT=-lc++
  RUNCXX=clang++
fi
sed -i -e 's|^ADD_LIB_GFORTRAN\t*=.*|ADD_LIB_GFORTRAN\t\t= -lgfortran|' \
       -e "s|^ADD_LIB_GPP\t*=.*|ADD_LIB_GPP\t\t= ${CXXRT}|" \
       -e "s|^CXX           = g++\$|CXX           = ${RUNCXX}|" \
       -e "s|/lib/libLHAPDF.so\$|/lib/libLHAPDF${SHLIB_EXT}|" \
       -e 's|^ROOTCONFIG *:=.*|ROOTCONFIG   := root-config|' \
       -e "s|^FFLAGS\t   = -O\$|FFLAGS\t   = -O ${LEGACY}|" \
       -e 's|^LDFLAGS       = -O$|LDFLAGS       = -O -Wl,-rpath,$(PATHLHAPDF)/lib|' \
       "$M"
# (the ROOT section's "LDFLAGS = -O" is the definition the final link uses:
#  the rpath makes run*.exe find LHAPDF/ROOT without LD_LIBRARY_PATH)
grep -q 'rpath,$(PATHLHAPDF)/lib' "$M"
grep -q "^ROOTCONFIG   := root-config" "$M"
grep -q -- "-fallow-argument-mismatch" "$M"
grep -q "^CXX           = ${RUNCXX}\$" "$M"
grep -q "libLHAPDF${SHLIB_EXT}\$" "$M"   # .dylib on macOS

# ---- run-independent libraries --------------------------------------------
# The three Makefiles hardcode /usr/bin/ar, /usr/bin/ranlib (and BASES a
# csh SHELL, although its rules are plain sh): use the conda toolchain's.
# BASES' uxtime_.c is K&R C ("long sysconf();" called with an argument),
# which C23 -- GCC 15+'s default -- reads as "takes none": build it as gnu17.
TOOLS=(SHELL=/bin/bash AR="${AR}" RANLIB="${RANLIB}" FC="${FC}" CC="${CC} -std=gnu17" FFLAGS="-O ${LEGACY}")
( cd basesv5.1 && make -f Makefile_gfortran.linux "${TOOLS[@]}" )   # BASES/SPRING integrator
( cd frag && make "${TOOLS[@]}" )                                    # fragmentation functions
( cd pdfa && make "${TOOLS[@]}" )                                    # nuclear PDFs
for lib in basesv5.1/libbases.a frag/libfrag.a pdfa/libpdfa.a; do
  test -s "$lib" || { echo "ERROR: $lib was not built" >&2; exit 1; }
done
rm -f basesv5.1/*.o frag/*.o pdfa/*.o

# ---- install ----------------------------------------------------------------
mkdir -p "${PREFIX}/share/jetphox" "${PREFIX}/bin"
cp -R basesv5.1 frag pdfa pawres src working Readme_jetphox.html "${PREFIX}/share/jetphox/"

cat > "${PREFIX}/bin/jetphox-init" <<'EOF'
#!/usr/bin/env bash
# jetphox-init <dir>: copy a ready-to-run JETPHOX tree into <dir>.
# Then edit <dir>/working/parameter.indat and run `perl start.pl` there.
set -euo pipefail
[ $# -eq 1 ] || { echo "usage: jetphox-init <dir>" >&2; exit 2; }
DEST="$1"
[ -e "$DEST" ] && { echo "jetphox-init: $DEST already exists" >&2; exit 1; }
PFX="$(cd "$(dirname "$0")/.." && pwd)"
cp -R "$PFX/share/jetphox" "$DEST"
# parameter.indat is positional: the LHAPDF prefix is the line right after
# the "# LHAPDF library path" comment (upstream default /usr/local).
# -i.bak and the ";" before "}": the same line for GNU and BSD (macOS) sed
sed -i.bak "/^# LHAPDF library path/{n;s|.*|$PFX|;}" "$DEST/working/parameter.indat"
rm -f "$DEST/working/parameter.indat.bak"
echo "JETPHOX tree ready in $DEST: edit $DEST/working/parameter.indat, then (cd $DEST/working && perl start.pl)"
EOF
chmod +x "${PREFIX}/bin/jetphox-init"
