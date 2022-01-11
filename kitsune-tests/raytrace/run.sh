KITSUNE_HOME=/home/pat/Projects/kitsune
KITSUNE_GPURT_HOME=$KITSUNE_HOME/kitsune/runtimes/GPU
KITSUNE_FLAGS="-O3 -fkokkos -fkokkos-no-init -ftapir=gpu"
PATH=$KITSUNE_HOME/build/local/bin:$PATH

KOKKOS_HOME=/opt/local/kokkos/cuda
PATH=$KOKKOS_HOME/bin:$PATH

rm -f kokkos.log
rm -f kitsune.log

echo "compiling kokkos path tracer..."
$KOKKOS_HOME/bin/nvcc_wrapper raytrace.cpp -O3 -o raytrace.kokkos -I$KOKKOS_HOME/include -I$KITSUNE_HOME/kitsune/include -L$KOKKOS_HOME/lib  -lkokkoscore > kokkos.log 2>&1
echo "done."
echo ""
echo ""

echo "compiling kitsune path tracer..."
clang++ -O3 -fkokkos -fkokkos-no-init raytrace2.cpp -ftapir=gpu -I$KITSUNE_HOME/kitsune/include/ -I$KITSUNE_GPURT_HOME -L$KITSUNE_GPURT_HOME -lllvm-gpu -o raytrace.kitsune > kitsune.log 2>&1
echo "done."
echo ""
echo ""


echo "running nvcc-kokkos path-tracer benchmark..."
nvprof -f --system-profiling on --kernel-latency-timestamps on --analysis-metrics --export-profile kokkos.nvp ./raytrace.kokkos 128 >> kokkos.log 2>&1

echo "running kitsune+kokkos path-tracer benchmark..."
nvprof -f --system-profiling on --kernel-latency-timestamps on --analysis-metrics --export-profile kitsune.nvp ./raytrace.kitsune 128 >> kitsune.log 2>&1
