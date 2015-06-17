#using example list:
  #total(template).stream()
  #total(template).readArray([],onProgress,onPost)
  #total(template).readIterator(iterator,onProgress,onPost)

__exports=(template)->
  new total(template)


class total
  constructor:(@template)->

  stream:()->
    through = require 'through'
    actuary = new Actuary
      template:@template
      onPost:(doc)->s.emit 'end',doc
      onProgress:(doc)->s.emit 'data',doc

    s = through ((doc)->actuary.write(doc)), ->actuary.end()
    return s

  readArray:(array,onPost,onProgress)->
    actuary = new Actuary
      template:@template
      onPost:onPost
      onProgress:onProgress

    for item in array
      actuary.write(item)
    actuary.end()
    actuary.cache

  readIterator:(iterator,onPost,onProgress)->
    if iterator? and iterator.hasNext?() and 'function'==typeof iterator.next
      actuary = new Actuary
        template:@template
        onPost:onPost
        onProgress:onProgress
      while iterator.hasNext()
        actuary.write(iterator.next())
      actuary.end()
      actuary.cache

__exports.Actuary =
  class Actuary
    constructor:(option)->
      {@template,@onPost,@onProgress}=option
      @operators = parse @template
      if @operators.length ==0
        throw new Error "You must set template!"
      @operators.count = 0
      @cache ={}

    write:(doc)->
      @operators.count++
      exec @operators, doc
      setPathValue(@cache, @operators)
      @onProgress(@cache)

    end:->
      exec @operators
      setPathValue(@cache, @operators)
      @onPost(@cache)


exec = (operators, doc)->
  if(doc)
    (
#      op.cache = operators.cache
      op.count = operators.count
      op.value = op.exec doc, operators.count
    )for op in operators
  else
    (op.value = op.exec null, operators.count) for op in operators when op.atEnd
  return


__exports.parse = parse = (template, path)->
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
        value: null #for result,缓存操作符的计算结果,遍历所有数据记录后，作为结果返回
        prevalue: null #一般统计方法中用于缓存上次计算结果
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

__exports.sum = sum = (array)->
  ret = 0
  (ret += (value || 0)) for value in array
  ret

__exports.avg = avg = (array)->
  count = array.length;
  if count == 0 then 0 else sum(array) / count

__exports.product = product = (array)->
  if array.length == 0
    return 0
  prd = 1;
  (prd *= p) for p in array
  return prd

##export normal Math library
__exports.abs = abs = Math.abs
__exports.pow = pow = Math.pow
__exports.sqrt = sqrt = Math.sqrt
#取整操作类方法
__exports.floor = floor = Math.floor
__exports.ceil = ceil = Math.ceil
__exports.round = round = Math.round

__exports.square = square = (x)-> x * x
__exports.max = max = ()->
  arr = []
  (
    if param instanceof Array
      arr = arr.concat(param)
    else
      arr.push(param)
  )for param in arguments
  Math.max.apply(null, arr)

__exports.min = min = ()->
  arr = []
  (
    if param instanceof Array
      arr = arr.concat(param)
    else
      arr.push(param)
  )for param in arguments
  Math.min.apply(null, arr)


#计算向下取指定count总量占比率percent值后去余值mod
__exports.floorPercentValue = __exports.floorPV = floorPV = (count, percent, mod)->
  d_count = floor count * percent
  d_count -= d_count % (mod || 2)

#简单的数组中数据点排序
__exports.sort = sort = (array)->
  array.sort (a, b)->
    if a > b then 1 else if a < b then -1 else 0

#在数组头部与尾部中去除percent比率的数据点,0<percent<1,在调用前需对数组进行排序
__exports.wipeLeadTail = wipeLeadTail = (array, percent)->
  if 0 < percent < 1
    d_count = (floorPV array.length, percent) / 2
    array[d_count..(-1) * (d_count + 1)]

#拾取数组头部与尾部percent比率的数据点,在调用前需对数组进行排序
__exports.pickLeadTail = pickLeadTail = (array, percent)->
  if 0 < percent < 1
    d_count = (floorPV array.length, percent) / 2
    array[0..d_count - 1].concat array[(d_count) * -1..]

__exports.getValues = getValues = (doc, args, count)->
  for key in args
    switch typeof key
      when 'function' then key(doc, count)
      when 'string' then getValue(doc, key)
      else
        key
#获取对象doc指定属性路径path的值，若未指定doc,则返回get
__exports.select = getValue = (doc, path)->
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

__exports.openPath = openPath = (obj, path)->
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
__exports.use = use = (method, totalfn, atEnd)->
  ops[method] = if 'function' == typeof totalfn then totalfn else ()->;
  if atEnd
    ops.ends[method] = ops[method] isnt null
  return

#下列代码是各操作符的定义
#求和
use '$sum', (doc, count)->
  @prevalue = @prevalue || 0
  @prevalue += sum(getValues doc, @args, count)

#求平均数
use '$avg', (doc, count)->
  @prevalue = @prevalue || 1
  @prevalue = sum ([@prevalue * (count - 1), avg(getValues doc, @args, count)])
  @prevalue /= count

#统计记录数
use '$count', (doc, count)-> @prevalue = count

#求最大数
use '$max', (doc, count)->
  args = getValues doc, @args, count
  args.push(@prevalue || args[0])
  @prevalue = max args

#求最小数
use '$min', (doc, count)->
  args = getValues doc, @args, count
  args.push(@prevalue || args[0])
  @prevalue = min args

#求数的乘积
use '$product', (doc, count)->
  tmp = product(getValues(doc, @args, count))
  if count == 1
    @prevalue = tmp
  else
    @prevalue *= tmp

#样本标准偏差
use '$stdev_s', ((doc, count)->
  if doc
    @values = (@values || []).concat getValues(doc, @args, count)
    d_avg = avg(@values) #获取数组的平均值(1)
    d_values = ( square(value - d_avg) for value in @values) #取得每个数与平均值差的平方数数组(2)
    @prevalue = if d_values.length <= 1 then 0 else sqrt sum(d_values) / (d_values.length - 1)#取得(2)所有数的和除以n-1再开根号(3)
  else
    delete @values
  @prevalue
), true

#总体标准偏差
use '$stdev_p', ((doc, count)->
  if doc
    @values = (@values || []).concat(getValues(doc, @args, count))
    d_avg = avg(@values) #获取数组的平均值(1)
    d_values = ( square(value - d_avg) for value in @values) #取得每个数与平均值差的平方数数组(2)
    @prevalue = if d_values.length then sqrt avg(d_values) else 0 #取得(2)所有数的和除以n再开根号(3)
  else
    delete @values
  @prevalue
), true

#求数组中数据项与他们平均数的绝对偏差平均数
use '$avedev', ((doc, count)->
  if(doc)
    @values = (@values || []).concat(getValues(doc, @args, count))
    d_avg = avg(@values) #取得数组元素的平均值(1)
    @prevalue = avg (abs(value - d_avg) for value in @values)#取得数组元素的每个值与平均数的差绝对值平均数(2)
  else
    delete @values
  @prevalue
), true

#求出现频率最高的值
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

#求偏差的平方和
use 'devsq', ((doc, count)->
  if(doc)
    @values = (@values || []).concat getValues(doc, @args, count)
    d_avg = avg(@values) #取平均值
    @prevalue = sum(square(value - d_avg) for value in @values)#求偏差的平方和
  else
    delete @values #清除计算过程数据
  @prevalue
), true

#求内部平均值
use '$trimmean', ((doc, count)->
  args = if @args[0] instanceof Array then @args[0] else @args[0..0]
  @percent = @args[1] || 0.1
  @percent = if 'function' == typeof @percent then @percent() else @percent
  @exec = (doc, count)->
    if doc
      @values = (@values || []).concat getValues(doc, args, count)
      @prevalue = avg wipeLeadTail(sort(@values), @percent)#去除首尾占比数据点后平均值
    else
      delete @values #清除计算过程数据
    @prevalue
  @exec(doc, count)
), true

#求值的区间分布频率
use '$frequency', ((doc, count)->
#初始化函数相关信息
  fields = if @args[0] instanceof Array then @args[0] else @args[0..0]
  #取得区间从小到大数值
  zone = []
  (zone = zone.concat if 'function' == typeof v then v.call(this) else v )for v in @args[1..]
  zone = sort(zone)
  @prevalue = []
  val = zone[0]
  @prevalue.push #生成区间最小边界
    name: "#{fields.join(',')}<#{val}"
    bound: val
    freq: 0
  for v in zone[1..]
    @prevalue.push
      name: "#{val}<=#{fields.join(',')}<#{v}"
      bound: val = v
      freq: 0
  @prevalue.push last = #生成区间最大边界
    name: "#{fields.join(',')}>=#{val}"
    bound: val
    freq: 0

  @exec = (doc, count)->#重置统计函数
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

##exports
if exports? and module? and module.exports?
  exports = module.exports = __exports
#

##for AMD
if 'function' == typeof define and define.amd?
  define null, [], ->
    __exports