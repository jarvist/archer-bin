# No hash bang, so you'd hopefully stop and think :^)
#
# Deletes old temporary FILES; compresses irreularly used (and compressible) files.

for delete in "WAVECAR*" "core"
do
 echo "Deleting +30 day ${delete}..."
 find . -type f -name "${delete}" -mtime +30 -exec rm {} \; -print
done

for gzipping in "*vasprun.xml" "XDATCAR" "EIGENVAL"
do
 echo "Gzipping +30 day ${gzipping}..."
 find . -type f -name "${gzipping}" -mtime +30 -exec gzip {} \; -print
done
