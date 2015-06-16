Stream = require('stream')
total = require('../total')

generator = (n) ->
  s = new Stream
  i = 1

  next = ->
    s.emit 'data',
      name: 'name ' + i
      value: Math.floor((i + Math.random()) * 100)
      age: Math.floor(i * 100* Math.random()%70)
      n_value:i
      grade:
        name: 'grade ' + (i % 6 + 1)
    i++
    if i == n
      s.emit 'end'
    else
      process.nextTick next
    return

  s.readable = true
  process.nextTick next
  s

total.use '$custom',(doc,count)->
  ret = total.sum(total.getValues(doc,@args,count))
  if count==1
    @prevalue=ret
  else
    @prevalue *= ret

generator(100)
.pipe(total(
    ageAvg:
      $avg: [
        'age'
      ]
    count:
      $count: '*'
    sum:
      ageSum:
        $sum: 'age'
      valueSum:
        $sum:'value'
    ageMax:
      $max: [
        'age'
#        (doc) ->
#          doc['value' ]
      ]
    minAge:
      $min: ['age']
    modeGrade:
      $mode:'grade.name'
    modeAge:
      $mode : 'age'
    avedev:
      $avedev:'age'
    stdev_s:
      $stdev_s:['age']
    stdev_p:
      $stdev_p:'age'
    custom:
      $custom:'n_value'
    product:
      $product:'n_value'
    trimmean:
      $trimmean:['age',0.4]
    frequency:
      $frequency:
        ['age', 18, 10
         24
          ->(console.log this; 45)
         60]
  )
).on('data', (doc)->
#console.log doc
).once 'end', (result) ->
  console.log result
  console.log 'sum age:',total.select(result,'sum.ageSum')
  console.log total.select(result,'frequency')[0].values
