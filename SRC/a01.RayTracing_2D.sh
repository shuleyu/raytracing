#!/bin/bash

# ==============================================================
# This script calculate the 1D ray-tracing result.
#
# Shule Yu
# Spet 11 2014
# ==============================================================

echo ""
echo "--> `basename $0` is running."
rm -f ${WORKDIR}/${OutFilePrefix}* ${WORKDIR}/${PolygonOutPrefix}*
trap "rm -f ${WORKDIR}/tmpfile*$$ ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

# ==============================================
#           ! Work Begin !
# ==============================================

# C++ code.
${EXECDIR}/TraceIt.out 5 8 1 << EOF
${DebugInfo}
${TS}
${TD}
${RD}
${StopAtSurface}
${WORKDIR}/tmpfile_InputRays_${RunNumber}
${WORKDIR}/tmpfile_LayerSetting_${RunNumber}
${WORKDIR}/tmpfile_KeyDepths_${RunNumber}
${WORKDIR}/tmpfile_1DRef_${RunNumber}
${WORKDIR}/tmpfile_Polygons_${RunNumber}
${WORKDIR}/${OutFilePrefix}
${WORKDIR}/${ReceiverFile}
${WORKDIR}/${PolygonOutPrefix}
${CriticalAngle}
EOF

[ $? -ne 0 ] && echo "C++ code Failed ..." && rm -f tmpfile*$$ && exit 1

# Clean up.
rm -f tmpfile*$$

cd ${WORKDIR}

exit 0
