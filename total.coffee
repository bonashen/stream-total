through = require 'through'

exports = module.exports = total = (template)->
  operators = parse template
  operators.count = 0
  operators.cache = obj = {}
  s = through (
      (doc)->
        operators.count++
        exec operators, doc
        setPathValue(obj, operators)
        s.emit('data', obj)
    )
  , ()->
    exec operators
    setPathValue(obj, operators)
    s.emit('end', obj)
    return
  return s

exec = (operators, doc)->
  if(doc)
    (
      op.cache = operators.cache
      op.count = operators.count
      op.value = op.exec doc, operators.count
    )for op in operators
  else
    (op.value = op.exec null, operators.count) for op in operators when op.atEnd
  return


exports.parse = parse = (template, path)->
  parent = template
  path = path || []

  operators = []
  (
    value = parent[key]
    if '$' == key[0] or 'function' == typeof value
      operator =
        op: key, #.toLowerCase(),
        path: path.join('.')
        args: value,
        custom: if key[0] == '$' then false else true
        value: null #for result,����������ļ�����,�����������ݼ�¼����Ϊ�������
        prevalue: null #һ��ͳ�Ʒ��������ڻ����ϴμ�����
      #operator.exec =
      parseOp(operator)
      operators.push operator
    else
      if 'object' == typeof value
        operators = operators.concat parse(value, path.concat(key))
  ) for key of parent

  return operators

parseOp = (op)->
  if op.custom
    op.exec = (doc, count)->
      @prevalue = op.args.call(this, doc, count)
  else
    op.args = if !(op.args instanceof Array) then [op.args] else op.args
    (
      op.exec = ops[key]
      op.atEnd = ops.ends[key]
    ) for key of ops when key == op.op
  return

exports.sum = sum = (array)->
  ret = 0
  (ret += (value || 0)) for value in array
  ret

exports.avg = avg = (array)->
  count = array.length;
  if count == 0 then 0 else sum(array) / count

exports.product = product = (array)->
  if array.length == 0
    return 0
  prd = 1;
  (prd *= p) for p in array
  return prd

##export normal Math library
exports.abs = abs = Math.abs
exports.pow = pow = Math.pow
exports.sqrt = sqrt = Math.sqrt
#ȡ�������෽��
exports.floor = floor = Math.floor
exports.ceil = ceil = Math.ceil
exports.round = round = Math.round

exports.square = square = (x)-> x * x
exports.max = max = ()->
  arr = []
  (
    if param instanceof Array
      arr = arr.concat(param)
    else
      arr.push(param)
  )for param in arguments
  Math.max.apply(null, arr)

exports.min = min = ()->
  arr = []
  (
    if param instanceof Array
      arr = arr.concat(param)
    else
      arr.push(param)
  )for param in arguments
  Math.min.apply(null, arr)


#��������ȡָ��count����ռ����percentֵ��ȥ��ֵmod
exports.floorPercentValue = exports.floorPV = floorPV = (count, percent, mod)->
  d_count = floor count * percent
  d_count -= d_count % (mod || 2)

#�򵥵����������ݵ�����
exports.sort = sort = (array)->
  array.sort (a, b)->
    if a > b then 1 else if a < b then -1 else 0

#������ͷ����β����ȥ��percent���ʵ����ݵ�,0<percent<1,�ڵ���ǰ��������������
exports.wipeLeadTail = wipeLeadTail = (array, percent)->
  if 0 < percent < 1
    d_count = (floorPV array.length, percent) / 2
    array[d_count..(-1) * (d_count + 1)]

#ʰȡ����ͷ����β��percent���ʵ����ݵ�,�ڵ���ǰ��������������
exports.pickLeadTail = pickLeadTail = (array, percent)->
  if 0 < percent < 1
    d_count = (floorPV array.length, percent) / 2
    array[0..d_count - 1].concat array[(d_count) * -1..]

exports.getValues = getValues = (doc, args, count)->
  for key in args
    switch typeof key
      when 'function' then key(doc, count)
      when 'string' then getValue(doc, key)
      else
        key
#��ȡ����docָ������·��path��ֵ����δָ��doc,�򷵻�get
exports.select = getValue = (doc, path)->
  if arguments.length == 1
    [path,doc] = [doc, path]
  path = path.split '.'
  get = (obj)->
    lpath = path[..]
    ret = obj
    while key = lpath.shift()
      if ret[key]
        ret = ret[key]
      else
        ret = null
        break
    ret
  if doc then get(doc) else get

exports.openPath = openPath = (obj, path)->
  paths = if 'string' == typeof path then path.split '.' else path
  ret = obj
  while  path = paths.shift()
    ret = obj[path]
    obj = ret = obj[path] = if( ret and 'object' == typeof ret ) then ret else {}
  ret

setPathValue = (obj, operators)->
  (
    path = op.path.split '.'
    if op.custom
      path.push op.op
    field = path.pop()
    openPath(obj, path)[field] = op.value
  )for op in operators
  return

ops = {ends: {}};
exports.use = use = (method, totalfn, atEnd)->
  ops[method] = if 'function' == typeof totalfn then totalfn else ()->;
  if atEnd
    ops.ends[method] = ops[method] isnt null
  return

#���д����Ǹ��������Ķ���
#���
use '$sum', (doc, count)->
  @prevalue = @prevalue || 0
  @prevalue += sum(getValues doc, @args, count)

#��ƽ����
use '$avg', (doc, count)->
  @prevalue = @prevalue || 1
  @prevalue = sum ([@prevalue * (count - 1), avg(getValues doc, @args, count)])
  @prevalue /= count

#ͳ�Ƽ�¼��
use '$count', (doc, count)-> @prevalue = count

#�������
use '$max', (doc, count)->
  args = getValues doc, @args, count
  args.push(@prevalue || args[0])
  @prevalue = max args

#����С��
use '$min', (doc, count)->
  args = getValues doc, @args, count
  args.push(@prevalue || args[0])
  @prevalue = min args

#�����ĳ˻�
use '$product', (doc, count)->
  tmp = product(getValues(doc, @args, count))
  if count == 1
    @prevalue = tmp
  else
    @prevalue *= tmp

#������׼ƫ��
use '$stdev_s', ((doc, count)->
  if doc
    @values = (@values || []).concat getValues(doc, @args, count)
    d_avg = avg(@values) #��ȡ�����ƽ��ֵ(1)
    d_values = ( square(value - d_avg) for value in @values) #ȡ��ÿ������ƽ��ֵ���ƽ��������(2)
    @prevalue = if d_values.length <= 1 then 0 else sqrt sum(d_values) / (d_values.length - 1)#ȡ��(2)�������ĺͳ���n-1�ٿ�����(3)
  else
    delete @values
  @prevalue
), true

#�����׼ƫ��
use '$stdev_p', ((doc, count)->
  if doc
    @values = (@values || []).concat(getValues(doc, @args, count))
    d_avg = avg(@values) #��ȡ�����ƽ��ֵ(1)
    d_values = ( square(value - d_avg) for value in @values) #ȡ��ÿ������ƽ��ֵ���ƽ��������(2)
    @prevalue = if d_values.length then sqrt avg(d_values) else 0 #ȡ��(2)�������ĺͳ���n�ٿ�����(3)
  else
    delete @values
  @prevalue
), true

#��������������������ƽ�����ľ���ƫ��ƽ����
use '$avedev', ((doc, count)->
  if(doc)
    @values = (@values || []).concat(getValues(doc, @args, count))
    d_avg = avg(@values) #ȡ������Ԫ�ص�ƽ��ֵ(1)
    @prevalue = avg (abs(value - d_avg) for value in @values)#ȡ������Ԫ�ص�ÿ��ֵ��ƽ�����Ĳ����ֵƽ����(2)
  else
    delete @values
  @prevalue
), true

#�����Ƶ����ߵ�ֵ
use '$mode', (doc, count)->
  @prevalue = @prevalue || {}
  values = getValues(doc, @args, count)
  for value in values
    @prevalue[value] = @prevalue[value] || 0
    @prevalue[value]++
  t_count = 0
  ret = null
  for key,value of @prevalue
    if value > t_count
      t_count = value
      ret = key
  ret

#��ƫ���ƽ����
use 'devsq', ((doc, count)->
  if(doc)
    @values = (@values || []).concat getValues(doc, @args, count)
    d_avg = avg(@values) #ȡƽ��ֵ
    @prevalue = sum(square(value - d_avg) for value in @values)#��ƫ���ƽ����
  else
    delete @values #��������������
  @prevalue
), true

#���ڲ�ƽ��ֵ
use '$trimmean', ((doc, count)->
  args = if @args[0] instanceof Array then @args[0] else @args[0..0]
  @percent = @args[1] || 0.1
  @percent = if 'function' == typeof @percent then @percent() else @percent
  @exec = (doc, count)->
    if doc
      @values = (@values || []).concat getValues(doc, args, count)
      @prevalue = avg wipeLeadTail(sort(@values), @percent)#ȥ����βռ�����ݵ��ƽ��ֵ
    else
      delete @values #��������������
    @prevalue
  @exec(doc, count)
), true

#��ֵ������ֲ�Ƶ��
use '$frequency', ((doc, count)->
#��ʼ�����������Ϣ
  fields = if @args[0] instanceof Array then @args[0] else @args[0..0]
  #ȡ�������С������ֵ
  zone = []
  (zone = zone.concat if 'function' == typeof v then v.call(this) else v )for v in @args[1..]
  zone = sort(zone)
  @prevalue = []
  val = zone[0]
  @prevalue.push #����������С�߽�
    name: "#{fields.join(',')}<#{val}"
    bound: val
    freq: 0
  for v in zone[1..]
    @prevalue.push
      name: "#{val}<=#{fields.join(',')}<#{v}"
      bound: val = v
      freq: 0
  @prevalue.push last = #�����������߽�
    name: "#{fields.join(',')}>=#{val}"
    bound: val
    freq: 0

  @exec = (doc, count)->#����ͳ�ƺ���
    if doc
      values = getValues(doc, fields, count) || []
      for value in values
        if value >= last.bound
          last.freq++
        else
          (
            obj.freq++
            break
          )for obj in @prevalue when obj.bound > value
    @prevalue
  @exec doc, count
)