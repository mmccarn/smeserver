#!/bin/bash
# list of lists for conditional forwarding. Surround with quotes, separate with spaces
lists="zen.spamhaus.org"
lists="$lists bl.spamcop.net"

# truncate.gbudb.net does not have its own NS so we use gbudb.net
lists="$lists gbudb.net"
lists="$lists ix.dnsbl.manitu.net"
lists="$lists b.barracudacentral.org"
lists="$lists dbl.spamhaus.org"
lists="$lists rhsbl.sorbs.net"
lists="$lists multi.surbl.org"
lists="$lists black.uribl.com"
lists="$lists multi.uribl.com"

for list in $lists
do
  echo Processing $list
  
  # get the name servers for this list, then get their IPs
#  host -t ns $list |grep "name server " |sed 's/.*name server //' | \
  dig @8.8.8.8 +trace $list |grep $list.*NS |sed 's/.*NS\s*//' | \
  while read ns
  do
    printf "  $list\t$ns\n"
    host -i $ns |\
    grep 'has address' |\
    sed "s/.*has\ address\ /server=\/$list\//" 
  done 
done

