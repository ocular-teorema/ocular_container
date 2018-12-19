#!/bin/bash
GetJulianDay() {
  year=$1
  month=$2
  day=$3
  jd=$((day - 32075 + 1461 * (year + 4800 - (14 - month) / 12) / 4 + 367 * (month - 2 + ((14 - month) / 12) * 12) / 12 - 3 * ((year + 4900 - (14 - month) / 12) / 100) / 4))

  echo $jd
}

echo $(GetJulianDay $1 $2 $3)
