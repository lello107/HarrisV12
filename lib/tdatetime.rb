DELPHI_EPOCH = DateTime(1899, 12, 30).to_time.to_i
EPOCH = 0


def datetime_fromdelphi(dvalue)
    return DELPHI_EPOCH + timedelta(days=dvalue)
end