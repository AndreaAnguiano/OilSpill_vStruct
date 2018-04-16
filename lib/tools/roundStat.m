function nInt = roundStat(nDec)
floor_nDec = floor(nDec);
decimals = nDec-floor_nDec;
if decimals ~= 0
  rand_n = rand;
  if rand_n > decimals
    nInt = floor_nDec;
  else
    nInt = ceil(nDec);
  end
else
  nInt = nDec;
end
end