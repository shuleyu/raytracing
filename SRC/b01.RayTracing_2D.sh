#!/bin/bash

# ==============================================================
# This script plot the 1D ray-tracing result.
#
# Shule Yu
# Spet 11 2014
# ==============================================================

echo ""
echo "--> `basename $0` is running. "
mkdir -p ${PLOTDIR}/tmpdir_$$
cd ${PLOTDIR}/tmpdir_$$
trap "rm -rf ${PLOTDIR}/tmpdir_$$; exit 1" SIGINT EXIT

# Plot parameters.
gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 10p
gmtset LABEL_OFFSET = 0.05c

# ================================================
#         ! Work Begin !
# ================================================

# Check Calculation
ls ${WORKDIR}/${OutFilePrefix}* >/dev/null 2>&1
[ $? -ne 0 ] && echo "    !=> In `basename $0`: Run a01 first ..." && exit 1

# Plot.
Rotate=56.5
OUTFILE=tmp.ps
RE="6371.0"
PROJ="-JPa${PLOTSIZE}i/`echo ${Rotate} | awk '{print 90-$1}'`"
REG="-R0/360/0/${RE}"

# Move to center.
psxy ${PROJ} ${REG} -P -K -Xc -Yc > ${OUTFILE} << EOF
EOF

# Move to CenterAt.
X=`echo ${PLOTSIZE} ${CenterAt} ${Rotate}| awk '{print $3*cos(($4+$2)/180*3.1415926)/6371.0/2*$1}'`
Y=`echo ${PLOTSIZE} ${CenterAt} ${Rotate}| awk '{print -$3*sin(($4+$2)/180*3.1415926)/6371.0/2*$1}'`
psxy -J -R -O -K -X${X}i -Y${Y}i >> ${OUTFILE} << EOF
EOF

# distance grid.
psbasemap ${PROJ} ${REG} -Ba10f2 -O -K >> ${OUTFILE}

# plot mantle.
psxy ${PROJ} ${REG} -Sc${PLOTSIZE}i -G230/230/230 -O -K >> ${OUTFILE} << EOF
0 0
EOF

# plot transition zone.
psxy ${PROJ} ${REG} -Sc`echo "${PLOTSIZE}/${RE}*(${RE}-660/2-410/2)"| bc -l`i -W`echo "${PLOTSIZE}/${RE}*(660-410)/2" |bc -l`i,200/200/200 -O -K >> ${OUTFILE} << EOF
0 0
EOF

# plot outter core.
psxy ${PROJ} ${REG} -Sc`echo "${PLOTSIZE}/${RE}*3480.0"| bc -l`i -G170/170/170 -O -K >> ${OUTFILE} << EOF
0 0
EOF

# plot inner core.
psxy ${PROJ} ${REG} -Sc`echo "${PLOTSIZE}/${RE}*1221.5"| bc -l`i -G140/140/140 -O -K >> ${OUTFILE} << EOF
0 0
EOF

# plot ray path.
for file in `ls ${WORKDIR}/${OutFilePrefix}*`
do
    RayNumber=${file##*_}
    RayColor=`awk -v R=${RayNumber} 'NR==R {print $2}' ${WORKDIR}/${OutInfoFile}`

	grep -n ">" ${file} | awk 'BEGIN {FS=":"} {print $1}' > lines1
	awk '{print $1-1}' lines1 | awk 'NR>1 {print $0}' > lines2
	wc -l < ${file} >> lines2
	paste lines1 lines2 > lines

	while read l1 l2
	do
        if [ ${RayColor} = "black" ]
        then
            [ "`awk -v L1=${l1} 'NR==L1 {print $2}' ${file}`" = "P" ] && Pen="-W0.5p,blue" ||  Pen="-W0.5p,red"
        else
            Pen="-W0.5p,${RayColor}"
        fi
		awk -v L1=${l1} -v L2=${l2} '{ if (NR>L1 && NR<=L2) print $0}' ${file} | psxy ${PROJ} ${REG} -m -O -K ${Pen} >> ${OUTFILE}
	done < lines
done


# plot source.
awk '{print $1,$2}' ${WORKDIR}/tmpfile_InputRays_${RunNumber} | sort -u > tmpfile_sources_$$
while read theta depth
do
    psxy ${PROJ} ${REG} -Sa0.2i -Gyellow -N -O -K >> ${OUTFILE} << EOF
${theta} `echo "${RE}-${depth}" | bc -l`
EOF
done < tmpfile_sources_$$

# plot velocity anomalies.
for file in `ls ${WORKDIR}/${PolygonOutPrefix}*`
do
    psxy ${PROJ} ${REG} ${file} -m -L -W1p,black -O -K  >> ${OUTFILE}
done

# plot scale at the CMB.
PROJ2=`echo "${PLOTSIZE} ${Rotate}" | awk '{print "-JPa"$1*3480/6371"i/"90-$2}'`
MOVE=`echo "${PLOTSIZE}" |  awk '{print $1/2*2891/6371}'`
psbasemap ${PROJ2} ${REG} -Ba5f1 -X${MOVE}i -Y${MOVE}i -O -K >> ${OUTFILE}

# seal the plot.
psxy -J -R -O >> ${OUTFILE} << EOF
EOF

# Make PDF.
Title=`basename $0`
ps2pdf tmp.ps ${PLOTDIR}/${Title%.sh}.pdf
tomini ${PLOTDIR}/${Title%.sh}.pdf

exit 0
