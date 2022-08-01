
X_REGEX = /x=(\S+), y=(\S+)/
Y_REGEX = /y=(\S+), x=(\S+)/

class Ground
  @@water_chars = "|~".chars
  def initialize(grid, bottom)
    @grid = grid
    @bottom = bottom
  end

  def self.parse(text)
    sections = text.split("\n").flat_map { |line|
      if X_REGEX.match(line)
        x_group, y_group = X_REGEX.match(line).captures
      elsif Y_REGEX.match(line)
        y_group, x_group = Y_REGEX.match(line).captures
      else
        raise "Unmatched on line #{line}"
      end

      x_start, x_end = x_group.split("..").map(&:to_i)
      y_start, y_end = y_group.split("..").map(&:to_i)

      range(x_start, x_end, y_start, y_end)
    }.map { |point| [point, ?#] }
     .to_h

    sections[[500,0]] = ?+

    new(sections, sections.keys.map(&:last).max)
  end

  def self.range(x_start, x_end, y_start, y_end)
    raise "Got a box instead of a line: #{x_start}, #{x_end}, #{y_start}, #{y_end}" if !x_end.nil? && !y_end.nil?

    if x_end.nil?
      y_start.upto(y_end).map { |y| [x_start, y] }
    else
      x_start.upto(x_end).map { |x| [x, y_start] }
    end
  end

  def to_s
    ymn, ymx = 0, @bottom
    xmn, xmx = @grid.keys.map(&:first).minmax

    ymn.upto(ymx).map { |y|
      xmn.upto(xmx).map { |x|
        @grid[[x, y]] || ?.
      }.join
    }.join("\n")
  end

  def inspect
    "Ground:____________\n#{to_s}\n____________"
  end

  def full_capacity
    fall_from([500, 0])
    puts self
    water
  end

  def water
    @grid.values.count { |square| @@water_chars.include?(square) }
  end

  def water?(x, y)
    @@water_chars.include?(@grid[[x,y]])
  end

  def ground?(x, y)
    @grid[[x,y]] == ?#
  end

  def free?(x, y)
    !@grid.include?([x,y])
  end

  def source?(x, y)
    @grid[[x,y]] == ?+
  end

  def off_grid?(x, y)
    y > @bottom
  end

  def fall_from(point)
    x, y = point
    # puts "falling from #{point}\n#{self}\n\n"
    
    # If off_grid we don't make more water because there's infinite
    # water below this point.
    return if off_grid?(x, y)

    if water?(x, y)
      # Has reached a maybe-full pool, might increase water level
      fill_if_bound(x, y)
    elsif free?(x, y)
      # Falling into space still, just keep going
      @grid[[x,y]] = ?|
      fall_from([x, y+1])
      fill_if_bound(x, y+1)

      if @grid[[x, y+1]] == ?~
        bottom_layer(x, y)
      end
    elsif ground?(x, y)
      # Just hit the ground, definitely spill
      bottom_layer(x, y-1)
    elsif source?(x, y)
      # Just starting falling, least likely thing
      fall_from([x, y+1])
    else
      raise "Invalid value at #{[x,y].inspect}=>#{@grid[[x,y]]}"
    end
  end

  def bottom_layer(x, y)
    spill_left(x, y)
    spill_right(x, y)
    fill_if_bound(x, y)
  end

  def spill_left(x, y)
    spill(x, y, -1)
  end

  def spill_right(x, y)
    spill(x, y, +1)
  end

  def spill(x, y, direction)
    # puts "spilling from #{[x,y]}\n#{self}\n\n"
    # If there's a wall here, we've spilled as far as we can
    return ?~ if ground?(x, y)

    # If there's space below us, we should fall first, then
    # check if we filled a container below us, and if we
    # didn't, then there's nothing to spill to our side and we
    # should quit here
    if free?(x, y+1)
      fall_from([x,y]) # Sets this to ?| and falls from there
      return ?| if @grid[[x,y+1]] == ?|
    end
    
    @grid[[x,y]] = ?|
    ch = spill(x+direction, y, direction)
    @grid[[x,y]] = ch if ch == ?~

    return @grid[[x,y]]
  end

  def fill_if_bound(x, y)
    # puts "fill from #{[x,y]}\n#{self}\n\n"
    return if ground?(x+1, y)
    return if ground?(x-1, y)
    return if @grid[[x+1,y]] == @grid[[x-1,y]]
    return if @grid[[x+1,y]].nil? || @grid[[x-1,y]].nil?

    if @grid[[x+1,y]] == '~'
      fill_right(x, y)
    elsif @grid[[x-1,y]] == '~'
      fill_left(x, y)
    else
      raise "Invalid state at #{[x,y].inspect}=>#{@grid[[x-1,y]]}, #{@grid[[x,y]]}, #{@grid[[x+1,y]]}"
    end
  end

  def fill_left(x, y)
    fill(x, y, -1)
  end

  def fill_right(x, y)
    fill(x, y, +1)
  end

  def fill(x, y, direction)
    while water?(x, y)
      @grid[[x,y]] = ?|
      x += direction
    end
  end

  def bound(x, y)
    cursor = x
    while water?(cursor, y)
      cursor -= 1
    end

    left = cursor
    return unless ground?(cursor, y)

    cursor = x
    while water?(cursor, y)
      cursor += 1
    end

    right = cursor
    return unless ground?(cursor, y)

    [left, right]
  end
end

@example_bucket = <<scan.strip
x=495, y=5..7
x=505, y=5..7
y=7, x=495..505
x=490, y=3..10
x=510, y=3..10
y=10, x=490..510
scan

@example_overflow = <<scan.strip
x=493, y=6..7
x=498, y=4..7
y=7, x=493..498
x=490, y=3..10
x=510, y=3..10
y=10, x=490..510
scan

@example_channel = <<scan.strip
x=492, y=6..7
x=497, y=4..7
y=7, x=492..497
x=490, y=3..10
x=510, y=3..10
y=10, x=490..510
scan

@example = <<-scan.strip
x=495, y=2..7
y=7, x=495..501
x=501, y=3..7
x=498, y=2..4
x=506, y=1..2
x=498, y=10..13
x=504, y=10..13
y=13, x=498..504
scan

@input = <<-scan.strip
x=569, y=570..582
y=372, x=495..519
y=902, x=424..428
x=497, y=57..60
x=464, y=1698..1706
y=646, x=563..585
y=1193, x=534..550
x=595, y=342..347
x=473, y=1576..1585
x=491, y=910..922
x=570, y=1757..1769
x=473, y=199..211
x=560, y=1456..1469
y=279, x=588..612
y=82, x=523..525
y=1855, x=599..610
x=574, y=1681..1683
x=548, y=576..586
x=593, y=1012..1040
y=770, x=532..536
x=460, y=1160..1171
x=442, y=637..642
x=423, y=1139..1165
x=503, y=93..106
x=457, y=792..808
x=556, y=39..61
x=496, y=803..816
x=458, y=1382..1386
y=937, x=518..522
y=1313, x=568..570
y=1002, x=498..500
y=479, x=575..600
x=455, y=483..490
x=452, y=412..439
y=305, x=469..484
y=1239, x=448..462
x=483, y=1825..1834
x=416, y=21..22
x=571, y=343..353
x=475, y=1294..1298
x=478, y=893..904
x=527, y=11..14
y=918, x=502..504
y=1256, x=571..597
x=604, y=730..751
x=482, y=1491..1500
x=611, y=1657..1664
x=483, y=1331..1346
y=1450, x=454..476
y=80, x=419..424
x=410, y=1725..1748
y=1722, x=546..557
x=497, y=1347..1365
y=230, x=540..542
x=521, y=1079..1089
y=1408, x=566..584
x=481, y=994..998
y=1771, x=452..457
y=1690, x=456..534
y=1360, x=518..521
x=548, y=592..600
x=491, y=52..66
x=428, y=143..170
y=1398, x=521..537
x=528, y=933..946
x=506, y=1503..1514
x=422, y=1500..1506
x=461, y=36..57
x=500, y=1002..1004
x=444, y=1735..1747
y=587, x=470..489
x=513, y=442..451
x=491, y=313..324
y=441, x=482..487
y=324, x=489..491
x=425, y=468..496
x=529, y=664..667
y=1514, x=506..508
y=987, x=512..514
y=1796, x=432..475
x=534, y=575..586
x=548, y=223..240
x=544, y=291..298
x=518, y=409..411
x=571, y=1400..1402
x=476, y=1428..1450
y=689, x=561..563
y=527, x=517..519
x=543, y=1188..1190
x=456, y=614..626
y=17, x=490..493
x=598, y=1559..1569
x=473, y=710..714
y=127, x=516..538
x=527, y=1386..1395
x=516, y=1633..1646
y=769, x=414..420
x=544, y=514..525
x=547, y=1652..1663
x=485, y=896..898
y=264, x=518..524
y=1072, x=520..537
y=691, x=473..476
y=442, x=466..474
y=1521, x=429..436
x=482, y=516..528
x=473, y=688..691
y=1355, x=416..429
y=232, x=479..482
y=302, x=474..477
x=549, y=997..1012
y=823, x=423..434
y=258, x=564..567
x=466, y=424..442
y=574, x=420..423
x=451, y=1406..1409
y=337, x=433..435
x=490, y=514..525
x=507, y=978..990
x=612, y=999..1022
x=532, y=770..774
x=517, y=888..903
x=588, y=1251..1253
y=1168, x=451..453
x=489, y=143..156
x=601, y=1537..1539
y=1498, x=587..592
x=550, y=1223..1250
x=540, y=560..562
x=417, y=1613..1638
y=1566, x=471..487
x=437, y=513..516
y=1631, x=428..438
x=573, y=1547..1551
x=602, y=572..600
y=1836, x=564..584
x=562, y=705..716
y=421, x=556..568
x=423, y=1807..1817
x=454, y=1701..1710
y=1651, x=433..452
x=533, y=1077..1086
x=518, y=1346..1360
x=505, y=1158..1181
y=1519, x=551..554
y=1774, x=444..466
x=428, y=895..902
x=427, y=107..122
x=551, y=681..693
y=1152, x=560..577
x=432, y=1783..1796
x=543, y=1711..1714
x=440, y=830..838
y=995, x=592..610
y=1748, x=410..424
x=583, y=704..716
x=516, y=1512..1515
x=511, y=1097..1103
y=1063, x=597..612
x=437, y=708..728
x=610, y=376..379
x=605, y=1738..1755
x=442, y=79..88
y=21, x=485..501
x=520, y=409..411
x=489, y=313..324
x=453, y=1165..1168
x=598, y=789..802
x=484, y=315..327
x=557, y=557..567
x=417, y=407..417
x=594, y=1054..1076
x=597, y=1246..1256
y=1273, x=496..507
y=106, x=503..528
x=509, y=1538..1545
x=502, y=907..918
x=452, y=1767..1771
x=610, y=431..446
x=605, y=1223..1237
y=247, x=495..514
y=1483, x=473..540
y=325, x=507..523
x=584, y=270..293
x=559, y=1542..1562
x=612, y=502..523
x=586, y=1224..1237
x=445, y=656..678
x=523, y=193..208
x=481, y=1782..1792
y=1837, x=428..446
x=447, y=1715..1727
x=516, y=74..85
y=1335, x=471..473
x=588, y=268..279
y=1440, x=482..487
x=538, y=113..127
x=582, y=788..802
x=428, y=1592..1595
y=1777, x=474..501
y=541, x=566..568
x=603, y=999..1022
x=429, y=1512..1521
y=1050, x=515..535
x=593, y=1705..1710
x=418, y=1445..1453
x=510, y=909..922
y=1432, x=510..514
x=528, y=223..240
y=972, x=543..556
y=356, x=442..444
y=1111, x=571..573
y=640, x=574..577
x=531, y=496..498
y=1862, x=410..500
y=1076, x=591..594
y=1821, x=538..556
x=612, y=431..446
x=472, y=142..155
x=535, y=746..758
x=596, y=1591..1593
y=294, x=504..507
x=478, y=268..280
x=590, y=1560..1569
y=1648, x=443..445
x=528, y=1077..1086
y=1506, x=550..572
x=439, y=37..57
x=586, y=1013..1040
x=536, y=770..774
x=416, y=1336..1355
y=1769, x=567..570
x=523, y=72..82
y=1469, x=560..569
x=506, y=1448..1462
y=1750, x=437..456
y=971, x=454..478
y=405, x=573..601
y=781, x=576..596
y=751, x=597..604
x=464, y=1489..1499
y=1721, x=565..578
x=594, y=1621..1644
x=492, y=1827..1837
y=454, x=414..422
x=468, y=1856..1859
x=472, y=1406..1409
y=1744, x=489..515
x=537, y=1314..1327
y=1619, x=578..585
y=774, x=532..536
y=1237, x=586..605
x=425, y=1387..1393
y=274, x=603..606
y=1786, x=540..543
x=508, y=538..548
x=481, y=1179..1194
y=769, x=477..488
x=479, y=1294..1298
x=411, y=1612..1638
y=469, x=507..526
y=22, x=514..536
x=588, y=786..797
x=511, y=817..828
x=423, y=816..823
x=514, y=1632..1646
x=554, y=981..987
y=1545, x=484..491
x=417, y=1246..1254
y=1727, x=477..489
y=298, x=536..544
x=488, y=1787..1789
x=489, y=641..646
x=477, y=1576..1586
x=606, y=272..274
x=579, y=17..33
x=452, y=1376..1394
x=591, y=1108..1115
x=441, y=752..778
x=469, y=711..714
x=537, y=1389..1398
y=821, x=595..599
x=514, y=230..247
x=459, y=1489..1499
x=445, y=1356..1372
x=531, y=1733..1744
x=448, y=1232..1239
x=523, y=312..325
y=1506, x=526..531
y=170, x=428..451
x=523, y=1616..1627
y=1859, x=461..468
y=446, x=610..612
y=652, x=422..433
x=527, y=1406..1417
x=531, y=1058..1069
x=531, y=1386..1395
x=491, y=1169..1172
y=803, x=509..531
x=590, y=1251..1253
x=471, y=995..998
x=609, y=1519..1542
x=441, y=513..516
x=459, y=1177..1189
y=1091, x=486..507
y=1710, x=593..601
x=519, y=1412..1414
y=1789, x=486..488
x=581, y=853..857
x=528, y=1058..1069
y=11, x=524..527
y=88, x=476..502
x=486, y=740..747
x=537, y=1060..1072
x=575, y=455..479
x=542, y=228..230
x=505, y=137..149
x=500, y=849..860
x=607, y=1345..1357
x=426, y=178..190
y=963, x=491..493
y=342, x=542..557
x=612, y=572..600
x=610, y=1847..1855
x=556, y=1820..1821
y=1475, x=518..520
y=425, x=460..463
y=1608, x=464..509
x=575, y=1583..1597
x=432, y=592..608
x=580, y=910..913
x=434, y=1717..1730
x=525, y=72..82
x=495, y=1170..1172
y=1412, x=519..521
x=544, y=1550..1568
x=430, y=1449..1464
x=445, y=878..884
y=280, x=478..500
y=1777, x=575..598
x=504, y=180..191
x=593, y=1519..1542
x=463, y=1659..1669
y=792, x=559..572
y=390, x=583..585
y=791, x=479..501
x=510, y=336..350
x=427, y=1016..1026
x=562, y=1695..1704
x=469, y=199..211
y=714, x=469..473
y=379, x=588..610
x=547, y=1732..1744
y=498, x=531..538
x=453, y=517..544
y=1638, x=411..417
x=479, y=228..232
x=596, y=89..93
y=913, x=580..603
y=544, x=453..477
y=1194, x=470..481
y=967, x=562..584
x=444, y=388..399
y=496, x=425..441
y=1337, x=471..473
x=509, y=1594..1608
y=1499, x=459..464
x=483, y=1656..1662
y=898, x=485..491
x=442, y=352..356
y=331, x=571..585
x=451, y=1593..1595
y=1586, x=477..495
x=588, y=746..758
y=1365, x=486..497
x=454, y=1718..1730
x=569, y=1457..1469
y=1251, x=588..590
x=446, y=312..316
y=1235, x=519..532
y=1771, x=418..431
y=1207, x=478..489
y=1542, x=593..609
x=612, y=269..279
y=1092, x=554..560
x=541, y=207..217
y=184, x=439..460
x=574, y=640..642
y=911, x=464..466
x=489, y=1739..1744
y=120, x=472..493
x=518, y=1475..1477
x=563, y=630..646
x=587, y=1492..1498
x=494, y=27..39
x=515, y=596..602
x=550, y=1182..1193
y=1053, x=578..584
y=363, x=545..566
x=558, y=134..153
y=857, x=577..581
x=560, y=1143..1152
x=558, y=594..604
y=1085, x=422..431
y=327, x=484..500
y=802, x=582..598
x=550, y=255..272
x=500, y=1159..1181
x=414, y=434..454
y=1837, x=473..492
x=582, y=204..230
x=552, y=1100..1113
x=487, y=1557..1566
y=57, x=439..461
x=494, y=1112..1128
x=549, y=1081..1095
x=515, y=999..1008
y=211, x=469..473
x=473, y=681..685
x=556, y=396..421
x=609, y=197..200
x=477, y=765..769
y=523, x=587..612
x=491, y=1240..1254
y=155, x=472..475
x=488, y=708..710
y=1298, x=475..479
x=472, y=104..120
x=557, y=319..342
x=545, y=347..363
x=595, y=1286..1298
x=507, y=1262..1273
x=510, y=932..946
x=576, y=767..781
x=456, y=1515..1527
x=454, y=843..867
x=425, y=391..393
x=453, y=1544..1547
y=1545, x=509..532
y=1073, x=479..505
x=495, y=229..247
x=580, y=1012..1033
x=526, y=1288..1306
y=451, x=490..513
y=1834, x=532..534
y=1759, x=534..544
x=524, y=768..781
x=461, y=1284..1302
y=1190, x=540..543
x=540, y=228..230
x=429, y=4..12
x=464, y=202..214
x=597, y=731..751
x=486, y=1077..1091
x=550, y=281..286
y=409, x=518..520
y=1774, x=589..592
x=531, y=1500..1506
y=1683, x=550..574
y=1146, x=532..534
x=526, y=1499..1506
x=446, y=1834..1837
x=509, y=401..415
x=499, y=1085..1087
y=1134, x=411..438
x=493, y=291..301
x=492, y=514..525
x=502, y=703..713
y=1033, x=567..580
y=1417, x=508..527
x=489, y=1705..1727
x=599, y=1153..1169
y=213, x=506..510
y=1171, x=444..460
y=1562, x=559..583
y=494, x=446..474
y=417, x=417..426
y=441, x=558..561
x=592, y=105..133
x=506, y=1016..1029
y=1177, x=551..572
y=61, x=556..583
y=538, x=566..568
x=535, y=1038..1050
x=444, y=352..356
x=462, y=1231..1239
x=504, y=1315..1333
x=608, y=835..840
y=506, x=498..551
x=448, y=904..916
y=426, x=443..446
x=504, y=1782..1792
x=525, y=1201..1212
y=1462, x=601..604
x=501, y=8..21
x=535, y=282..286
x=553, y=1482..1486
x=484, y=292..305
x=521, y=1185..1194
x=578, y=1592..1619
x=518, y=930..937
y=390, x=526..529
x=589, y=1694..1714
x=489, y=1204..1207
y=609, x=482..504
y=1834, x=483..485
y=585, x=558..575
x=450, y=1735..1747
x=560, y=1088..1092
x=485, y=708..710
x=551, y=1572..1595
y=725, x=513..520
y=1194, x=517..521
y=1022, x=603..612
x=558, y=573..585
x=460, y=948..960
x=514, y=3..22
x=535, y=803..810
x=610, y=993..995
x=602, y=1302..1317
x=515, y=474..484
x=467, y=1113..1128
x=474, y=1774..1777
x=512, y=981..987
y=1515, x=516..530
x=514, y=981..987
x=411, y=1114..1134
x=429, y=945..969
x=570, y=1301..1313
y=960, x=444..460
x=568, y=538..541
x=566, y=1640..1647
x=454, y=950..956
y=451, x=569..577
x=438, y=1114..1134
y=133, x=577..592
x=469, y=1657..1662
x=586, y=1202..1212
x=598, y=89..93
x=521, y=1424..1437
y=430, x=511..515
x=550, y=1681..1683
x=536, y=1551..1568
x=476, y=577..579
y=1616, x=544..561
x=561, y=92..97
y=728, x=437..446
x=474, y=300..302
x=587, y=76..85
x=601, y=1704..1710
y=1087, x=492..499
x=514, y=575..586
x=418, y=279..302
x=412, y=378..398
x=533, y=645..647
y=778, x=436..441
y=199, x=570..597
x=515, y=1037..1050
x=595, y=816..821
x=460, y=916..937
x=470, y=1632..1645
x=485, y=248..257
x=522, y=136..149
x=496, y=1261..1273
y=1095, x=542..549
y=1506, x=422..448
x=534, y=1182..1193
x=463, y=416..425
y=60, x=497..508
x=467, y=879..884
x=609, y=314..320
x=551, y=396..404
x=561, y=1605..1616
x=585, y=18..33
x=534, y=1105..1110
x=584, y=1266..1279
y=624, x=544..557
y=1386, x=458..480
x=570, y=192..199
x=460, y=176..184
y=1714, x=543..550
y=153, x=548..558
x=460, y=417..425
x=566, y=348..363
y=946, x=510..528
y=1381, x=483..509
x=583, y=39..61
x=496, y=1731..1732
x=526, y=381..390
y=182, x=548..567
y=1595, x=428..451
x=477, y=378..397
y=1787, x=486..488
y=962, x=505..512
x=536, y=290..298
y=531, x=509..525
y=257, x=437..462
y=1663, x=547..566
x=454, y=966..971
x=545, y=560..562
x=484, y=1449..1462
x=479, y=1065..1073
x=537, y=478..480
y=1409, x=451..472
x=471, y=461..463
y=525, x=544..566
y=931, x=553..568
x=583, y=1154..1169
y=1165, x=423..435
x=505, y=960..962
x=458, y=1032..1039
x=603, y=272..274
x=469, y=740..747
x=590, y=76..85
x=501, y=212..221
y=463, x=467..471
x=538, y=307..311
x=554, y=1088..1092
x=482, y=1435..1440
x=566, y=1381..1408
x=534, y=1139..1146
y=33, x=579..585
y=1327, x=532..537
x=595, y=957..979
y=339, x=433..435
y=969, x=425..429
x=520, y=715..725
y=1704, x=540..562
y=1547, x=571..573
x=429, y=1174..1193
y=678, x=445..460
y=169, x=491..513
x=475, y=143..155
x=594, y=885..905
y=1856, x=461..468
x=523, y=1365..1377
x=581, y=664..669
x=542, y=1851..1857
x=531, y=791..803
y=630, x=588..602
x=427, y=982..998
x=522, y=423..434
y=693, x=551..569
y=930, x=469..471
x=558, y=428..441
x=477, y=1014..1037
x=484, y=1535..1545
x=525, y=521..531
x=532, y=1537..1545
x=427, y=830..838
x=538, y=1819..1821
x=446, y=708..728
x=561, y=428..441
x=478, y=967..971
x=491, y=1097..1103
x=418, y=1769..1771
y=667, x=529..541
y=1134, x=540..560
x=482, y=596..609
x=566, y=1172..1174
x=554, y=1519..1524
x=532, y=1139..1146
y=1103, x=491..511
y=903, x=517..536
x=482, y=638..649
x=441, y=468..496
x=433, y=1450..1464
x=467, y=616..626
x=519, y=360..372
y=998, x=471..481
x=491, y=1293..1297
x=461, y=1083..1106
x=565, y=1583..1597
x=449, y=3..12
x=480, y=1320..1325
x=560, y=1266..1279
x=524, y=11..14
x=601, y=398..405
y=415, x=509..528
x=573, y=885..905
y=397, x=477..500
y=1585, x=452..473
x=584, y=1381..1408
x=539, y=1080..1089
x=543, y=961..972
y=302, x=415..418
y=88, x=440..442
y=1245, x=506..509
x=531, y=478..480
x=560, y=536..545
x=415, y=179..190
x=434, y=1435..1446
y=1427, x=425..428
x=543, y=645..647
y=156, x=478..489
x=542, y=319..342
x=564, y=250..258
y=429, x=443..446
x=569, y=434..451
x=598, y=1816..1818
y=710, x=485..488
x=577, y=105..133
x=575, y=572..585
x=428, y=1835..1837
x=546, y=93..119
x=423, y=569..574
y=810, x=535..559
y=979, x=595..611
x=460, y=655..678
x=587, y=1656..1664
x=485, y=1285..1302
x=410, y=690..716
x=600, y=1177..1192
y=350, x=510..536
x=566, y=538..541
y=1302, x=461..485
x=604, y=1333..1335
x=483, y=30..42
x=595, y=1221..1234
x=479, y=1516..1527
x=464, y=1594..1608
y=22, x=416..435
x=556, y=961..972
x=587, y=342..353
x=504, y=907..918
x=507, y=1077..1091
x=476, y=334..345
x=538, y=496..498
x=432, y=413..439
x=550, y=1711..1714
x=513, y=716..725
x=508, y=1503..1514
x=579, y=1233..1240
x=527, y=1099..1113
x=549, y=727..737
x=450, y=1545..1547
x=612, y=1038..1063
x=467, y=483..490
x=577, y=853..857
y=1394, x=428..452
x=614, y=832..843
x=479, y=1538..1548
y=404, x=548..551
x=433, y=904..916
y=465, x=518..520
y=998, x=427..437
y=1437, x=499..521
x=548, y=254..272
y=1086, x=528..533
x=599, y=1847..1855
x=565, y=1719..1721
x=537, y=1224..1250
y=1551, x=571..573
x=596, y=768..781
x=544, y=612..624
y=1687, x=578..599
x=538, y=383..393
x=480, y=1491..1500
x=598, y=1221..1234
x=462, y=235..257
y=1250, x=537..550
y=1539, x=599..601
x=424, y=72..80
x=571, y=1247..1256
x=602, y=848..860
x=575, y=1286..1298
y=754, x=422..430
x=414, y=1386..1393
x=480, y=181..191
y=1744, x=531..547
x=435, y=337..339
x=559, y=1572..1595
x=572, y=1502..1506
y=1234, x=595..598
y=1633, x=551..573
x=470, y=574..587
x=452, y=1577..1585
x=515, y=1738..1744
x=587, y=501..523
x=497, y=574..586
x=500, y=268..280
x=567, y=570..582
y=685, x=473..491
x=600, y=1333..1335
x=516, y=637..649
y=347, x=592..595
x=520, y=463..465
x=507, y=294..298
y=480, x=531..537
x=464, y=899..911
x=574, y=727..737
x=457, y=556..571
x=538, y=1512..1530
x=492, y=539..548
x=544, y=1604..1616
y=1004, x=498..500
y=119, x=546..550
x=433, y=1638..1651
x=592, y=1493..1498
x=564, y=1811..1836
x=517, y=525..527
x=509, y=1373..1381
x=573, y=1628..1633
x=542, y=767..781
y=1115, x=562..579
x=439, y=175..184
x=497, y=1537..1548
y=39, x=490..494
x=493, y=5..17
y=342, x=414..441
x=493, y=940..963
y=85, x=587..590
x=473, y=1473..1483
x=606, y=811..824
x=444, y=947..960
x=566, y=1325..1336
y=562, x=540..545
x=532, y=1817..1834
y=904, x=478..497
y=1660, x=553..560
x=577, y=640..642
x=514, y=292..301
x=425, y=1484..1495
x=600, y=833..843
y=1316, x=558..576
y=1462, x=484..506
x=600, y=313..320
x=497, y=1239..1254
x=509, y=1229..1245
x=520, y=1475..1477
x=577, y=433..451
x=522, y=930..937
x=597, y=1109..1115
y=1627, x=452..523
x=583, y=8..11
y=646, x=489..497
x=446, y=126..136
x=428, y=1605..1631
x=600, y=1591..1593
y=1174, x=564..566
x=505, y=1065..1073
y=1706, x=462..464
y=1253, x=588..590
x=466, y=742..766
x=471, y=925..930
x=603, y=910..913
y=311, x=538..546
x=479, y=774..791
y=1377, x=523..546
y=649, x=482..516
y=1279, x=560..584
x=449, y=1265..1291
y=884, x=488..508
y=1457, x=601..604
x=578, y=1685..1687
x=516, y=52..66
x=480, y=1381..1386
y=1306, x=526..539
x=605, y=835..840
y=228, x=540..542
x=599, y=1302..1317
x=489, y=226..239
y=366, x=607..609
x=557, y=1719..1722
x=490, y=827..829
y=66, x=491..516
x=469, y=658..672
x=470, y=1700..1710
y=1402, x=571..577
y=878, x=511..529
x=488, y=765..769
y=230, x=570..582
x=500, y=316..327
y=393, x=422..425
x=584, y=1810..1836
x=526, y=1017..1029
x=461, y=813..836
x=567, y=251..258
x=431, y=1769..1771
x=509, y=521..531
x=486, y=1347..1365
x=513, y=696..702
x=452, y=270..277
y=1792, x=481..504
y=1857, x=542..546
x=480, y=248..257
y=626, x=435..456
y=1148, x=568..571
x=422, y=592..608
y=1415, x=475..488
x=609, y=9..11
x=599, y=816..821
x=584, y=940..967
x=475, y=1783..1796
y=240, x=528..548
x=508, y=1406..1417
x=440, y=80..88
x=518, y=463..465
x=455, y=1017..1026
x=438, y=1436..1446
y=1664, x=587..611
y=669, x=581..598
x=420, y=570..574
x=491, y=1535..1545
x=589, y=811..824
x=595, y=1439..1465
y=12, x=429..449
x=543, y=1325..1336
x=525, y=1824..1852
x=568, y=396..421
x=471, y=1493..1504
y=1601, x=516..519
y=1069, x=528..531
y=836, x=454..461
y=1465, x=595..610
x=414, y=763..769
y=484, x=515..543
y=93, x=596..598
x=473, y=1747..1759
x=497, y=641..646
x=428, y=503..531
x=532, y=194..208
x=588, y=376..379
x=518, y=259..264
y=560, x=540..545
x=516, y=114..127
y=1755, x=601..605
x=527, y=1775..1797
y=1797, x=527..529
x=576, y=1303..1316
y=293, x=570..584
x=519, y=1595..1601
x=520, y=1061..1072
y=639, x=463..473
x=536, y=336..350
x=599, y=1537..1539
x=601, y=1457..1462
x=590, y=1176..1192
y=362, x=434..452
x=569, y=682..693
y=531, x=428..447
x=444, y=1160..1171
y=1669, x=439..463
y=1530, x=538..560
y=1254, x=410..417
x=443, y=426..429
x=550, y=592..600
x=584, y=1049..1053
y=956, x=450..454
y=391, x=422..425
x=454, y=1319..1325
x=551, y=493..506
x=577, y=1142..1152
x=429, y=1337..1355
x=591, y=1053..1076
y=586, x=497..514
x=495, y=617..626
x=583, y=364..390
x=451, y=742..766
y=1254, x=491..497
x=498, y=493..506
x=424, y=1300..1325
y=244, x=568..591
x=590, y=1578..1599
y=149, x=505..522
x=470, y=1178..1194
y=545, x=560..575
y=1591, x=596..600
x=540, y=1141..1155
x=550, y=94..119
y=1392, x=549..556
x=475, y=1398..1415
x=568, y=238..244
y=600, x=602..612
x=562, y=1098..1115
x=435, y=1139..1165
x=588, y=890..902
x=498, y=517..528
x=597, y=1038..1063
y=1333, x=491..504
x=491, y=160..169
x=433, y=337..339
y=1547, x=450..453
x=501, y=774..791
x=444, y=1715..1727
x=572, y=1164..1177
y=525, x=517..519
x=454, y=1429..1450
y=1317, x=599..602
y=353, x=571..587
y=1325, x=454..480
y=439, x=432..452
y=1346, x=459..483
y=136, x=446..462
y=642, x=574..577
y=277, x=437..452
x=598, y=1751..1777
x=471, y=1556..1566
y=1113, x=527..552
y=1747, x=444..450
y=647, x=533..543
x=456, y=1737..1750
y=398, x=412..431
x=521, y=1412..1414
x=592, y=1772..1774
y=1291, x=433..449
y=1336, x=543..566
y=411, x=518..520
y=737, x=549..574
y=85, x=516..535
y=1500, x=480..482
y=260, x=473..491
x=560, y=1121..1134
x=519, y=1824..1852
y=1817, x=423..490
x=529, y=381..390
x=602, y=198..200
x=426, y=407..417
x=539, y=1289..1306
x=489, y=575..587
x=563, y=1430..1434
y=937, x=460..481
x=414, y=324..342
y=1593, x=596..600
y=1189, x=439..459
y=713, x=478..502
x=548, y=134..153
x=503, y=29..42
x=446, y=426..429
x=575, y=535..545
x=519, y=384..393
y=1597, x=565..575
x=474, y=423..442
x=559, y=804..810
x=542, y=1080..1095
y=1730, x=434..454
x=536, y=3..22
y=1357, x=534..607
y=816, x=595..599
x=541, y=595..604
y=257, x=480..485
y=1181, x=500..505
x=448, y=1501..1506
x=474, y=481..494
y=1569, x=590..598
y=1446, x=434..438
x=544, y=1750..1759
x=566, y=1652..1663
y=716, x=410..422
y=11, x=583..609
x=567, y=659..672
y=1110, x=534..538
x=529, y=1182..1198
x=477, y=1704..1727
x=445, y=1083..1106
x=592, y=992..995
x=567, y=1758..1769
x=570, y=271..293
x=452, y=1637..1651
x=436, y=753..778
x=585, y=92..97
y=1714, x=583..589
y=1548, x=479..497
y=1393, x=414..425
x=491, y=681..685
y=1089, x=521..539
x=422, y=433..454
y=478, x=531..537
x=466, y=1761..1774
y=816, x=482..496
x=548, y=397..404
x=433, y=637..652
x=521, y=1388..1398
x=490, y=441..451
y=828, x=511..537
y=626, x=467..495
x=573, y=1640..1647
y=1297, x=491..494
x=410, y=1245..1254
y=316, x=438..446
x=597, y=192..199
x=479, y=826..829
x=511, y=872..878
x=598, y=664..669
x=487, y=430..441
y=1325, x=412..424
x=440, y=1033..1039
y=1372, x=445..460
x=483, y=1373..1381
x=573, y=1109..1111
y=1029, x=506..526
x=517, y=1185..1194
x=446, y=480..494
x=481, y=915..937
x=557, y=613..624
x=540, y=1472..1483
x=541, y=1429..1434
y=1434, x=541..563
y=600, x=548..550
x=429, y=550..570
x=607, y=253..259
y=608, x=422..432
x=461, y=1856..1859
x=563, y=819..825
y=352, x=442..444
x=528, y=94..106
y=1040, x=586..593
y=1732, x=496..509
x=538, y=206..217
x=604, y=1457..1462
x=494, y=1292..1297
x=498, y=1747..1759
y=191, x=480..504
y=829, x=479..490
y=571, x=441..457
x=415, y=279..302
x=523, y=1142..1155
x=437, y=236..257
x=497, y=894..904
y=567, x=481..557
y=1169, x=583..599
x=478, y=1204..1207
x=422, y=690..716
y=840, x=605..608
y=1495, x=416..425
x=540, y=1766..1786
x=485, y=7..21
x=509, y=792..803
x=473, y=1828..1837
x=560, y=1658..1660
x=462, y=126..136
x=500, y=1848..1862
y=1115, x=591..597
x=507, y=312..325
y=1477, x=518..520
y=298, x=504..507
y=825, x=563..576
x=437, y=1738..1750
x=546, y=1364..1377
y=969, x=499..518
x=511, y=426..430
y=672, x=469..567
y=1198, x=508..529
x=415, y=107..122
x=444, y=1761..1774
x=575, y=1751..1777
y=1662, x=469..483
y=916, x=433..448
x=611, y=958..979
x=508, y=870..884
y=922, x=491..510
x=504, y=294..298
x=452, y=345..362
x=441, y=555..571
x=537, y=981..987
y=602, x=515..521
x=571, y=1140..1148
y=1192, x=590..600
x=606, y=1577..1599
x=568, y=912..931
y=960, x=505..512
x=441, y=325..342
x=470, y=225..239
x=585, y=1593..1619
x=433, y=1264..1291
x=538, y=1105..1110
x=490, y=27..39
x=471, y=1335..1337
y=301, x=493..514
x=510, y=1428..1432
x=568, y=1140..1148
x=560, y=1513..1530
y=1037, x=477..479
x=585, y=306..331
x=534, y=1346..1357
x=543, y=475..484
x=463, y=634..639
x=585, y=631..646
y=808, x=434..457
x=482, y=803..816
y=399, x=444..469
y=1008, x=492..515
y=1106, x=445..461
x=436, y=1513..1521
x=533, y=997..1012
x=571, y=1109..1111
x=548, y=1331..1333
x=578, y=1048..1053
x=485, y=1825..1834
x=439, y=1658..1669
y=570, x=429..431
x=572, y=782..792
x=434, y=817..823
y=797, x=588..592
x=420, y=1174..1193
x=529, y=1775..1797
x=491, y=1314..1333
x=473, y=635..639
x=529, y=871..878
x=557, y=1331..1333
x=495, y=335..345
y=586, x=534..548
x=609, y=346..366
x=501, y=423..434
x=521, y=595..602
y=190, x=415..426
x=499, y=1425..1437
x=477, y=300..302
x=562, y=939..967
x=571, y=307..331
x=549, y=1378..1392
y=548, x=492..508
y=122, x=415..427
y=200, x=602..609
x=583, y=1695..1714
y=716, x=562..583
x=489, y=1494..1504
x=424, y=894..902
y=896, x=485..491
x=463, y=710..716
x=439, y=1177..1189
x=488, y=1398..1415
y=320, x=600..609
x=498, y=1002..1004
x=553, y=911..931
x=454, y=813..836
x=428, y=1402..1427
y=1155, x=523..540
y=14, x=524..527
y=902, x=586..588
x=460, y=637..642
x=600, y=454..479
x=506, y=1229..1245
y=702, x=513..530
x=502, y=78..88
x=451, y=1165..1168
x=491, y=941..963
x=481, y=577..579
y=1026, x=427..455
y=981, x=512..514
x=476, y=77..88
x=416, y=1484..1495
y=1767, x=452..457
y=221, x=497..501
x=508, y=57..60
x=513, y=159..169
x=497, y=212..221
x=551, y=1519..1524
y=1012, x=533..549
x=452, y=711..716
x=490, y=1807..1817
y=97, x=561..585
x=567, y=177..182
x=546, y=307..311
y=824, x=589..606
x=478, y=1638..1640
x=550, y=1503..1506
y=1645, x=470..488
y=1039, x=440..458
x=515, y=426..430
x=473, y=1335..1337
x=430, y=734..754
y=272, x=603..606
x=585, y=252..259
x=534, y=1749..1759
x=469, y=291..305
x=564, y=1172..1174
y=758, x=535..588
x=491, y=896..898
x=570, y=1482..1486
x=469, y=925..930
x=532, y=1232..1235
y=1073, x=471..476
x=561, y=679..689
x=471, y=1051..1073
x=592, y=786..797
y=716, x=452..463
y=1414, x=519..521
y=860, x=500..602
y=393, x=519..538
x=412, y=1301..1325
x=492, y=998..1008
x=413, y=1445..1453
x=437, y=982..998
y=1504, x=471..489
y=1772, x=589..592
x=588, y=614..630
y=1759, x=473..498
y=525, x=490..492
x=540, y=1188..1190
y=228, x=479..482
y=1640, x=476..478
x=445, y=1635..1648
x=452, y=1616..1627
x=577, y=1400..1402
x=536, y=888..903
x=478, y=144..156
x=425, y=945..969
x=514, y=1428..1432
x=478, y=704..713
x=537, y=818..828
x=591, y=237..244
x=431, y=379..398
x=507, y=459..469
x=571, y=1547..1551
x=480, y=201..214
x=543, y=1765..1786
y=1172, x=491..495
y=1240, x=575..579
y=286, x=535..550
y=579, x=476..481
y=214, x=464..480
y=766, x=451..466
y=1486, x=553..570
x=481, y=558..567
x=425, y=1401..1427
y=1644, x=594..612
x=422, y=735..754
x=435, y=20..22
x=528, y=401..415
y=838, x=427..440
y=604, x=541..558
x=591, y=1816..1818
x=434, y=345..362
x=559, y=781..792
x=435, y=614..626
x=473, y=251..260
y=1852, x=519..525
y=1710, x=454..470
y=217, x=538..541
x=558, y=1304..1316
x=521, y=1346..1360
x=601, y=1739..1755
y=781, x=524..542
x=586, y=890..902
x=463, y=843..867
x=578, y=1719..1721
x=438, y=313..316
x=610, y=1440..1465
x=451, y=142..170
x=486, y=1787..1789
y=747, x=469..486
x=431, y=1078..1085
x=422, y=638..652
x=476, y=1638..1640
y=867, x=454..463
y=1128, x=467..494
x=551, y=1163..1177
x=592, y=342..347
x=509, y=1730..1732
x=575, y=1233..1240
x=491, y=250..260
x=540, y=1695..1704
x=540, y=1121..1134
y=884, x=445..467
y=1212, x=525..586
y=843, x=600..614
y=1333, x=548..557
x=438, y=1604..1631
x=535, y=75..85
y=905, x=573..594
y=516, x=437..441
y=1599, x=590..606
x=459, y=1330..1346
x=420, y=764..769
x=566, y=514..525
x=456, y=1679..1690
x=443, y=1635..1648
y=208, x=523..532
x=607, y=346..366
x=424, y=1724..1748
x=579, y=1098..1115
x=457, y=1767..1771
x=422, y=1077..1085
x=570, y=204..230
x=567, y=1012..1033
x=553, y=1658..1660
x=476, y=1052..1073
x=467, y=460..463
y=1595, x=551..559
x=519, y=1232..1235
x=479, y=1013..1037
x=500, y=378..397
x=495, y=359..372
x=526, y=458..469
x=434, y=792..808
x=534, y=1678..1690
x=568, y=1301..1313
y=1464, x=430..433
y=1527, x=456..479
x=437, y=270..277
x=488, y=870..884
x=419, y=72..80
y=1647, x=566..573
y=1818, x=591..598
y=1727, x=444..447
x=482, y=429..441
x=450, y=950..956
y=345, x=476..495
x=410, y=1849..1862
x=447, y=504..531
x=518, y=958..969
y=1453, x=413..418
x=476, y=689..691
y=239, x=470..489
x=508, y=1181..1198
x=477, y=518..544
x=612, y=1622..1644
y=490, x=455..467
y=1105, x=534..538
x=599, y=1684..1687
x=551, y=1629..1633
x=501, y=1774..1777
x=585, y=363..390
x=546, y=1719..1722
x=563, y=679..689
y=582, x=567..569
y=1298, x=575..595
x=487, y=1434..1440
x=460, y=1355..1372
x=556, y=1377..1392
x=530, y=1511..1515
y=1646, x=514..516
x=532, y=1313..1327
x=541, y=664..667
x=422, y=391..393
x=490, y=5..17
y=987, x=537..554
x=492, y=1085..1087
y=1193, x=420..429
x=548, y=176..182
x=504, y=596..609
x=602, y=613..630
x=546, y=1850..1857
x=499, y=957..969
x=576, y=818..825
x=512, y=960..962
x=530, y=697..702
x=524, y=259..264
y=528, x=482..498
x=573, y=399..405
x=534, y=1816..1834
y=434, x=501..522
x=488, y=1632..1645
x=495, y=1576..1586
x=428, y=1376..1394
x=519, y=525..527
y=272, x=548..550
x=527, y=977..990
y=1335, x=600..604
x=493, y=105..120
x=516, y=1596..1601
y=259, x=585..607
y=1524, x=551..554
y=1568, x=536..544
x=510, y=196..213
y=42, x=483..503
y=1395, x=527..531
y=990, x=507..527
y=642, x=442..460
x=462, y=1698..1706
x=469, y=387..399
x=431, y=549..570
x=466, y=899..911
x=506, y=197..213
x=482, y=228..232
x=583, y=1541..1562
x=589, y=1772..1774
scan