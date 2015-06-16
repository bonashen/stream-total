#stream-total

total for stream json object.it's stream collection toolkit.

##example

```coffeescript
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
```

##extend total function
extend total function,you can use **total.use** define function.the function name's first letter is **$**.
example:
```javascript
total.use('$custom', function(doc, count) {
  var ret;
  ret = total.sum(total.getValues(doc, this.args, count));
  if (count === 1) {
    return this.prevalue = ret;
  } else {
    return this.prevalue *= ret;
  }
});
```
using example:
```javascript
generator(100)
.pipe(total({product:{$custom:'age'}}))
.once('end',function(result){
    console.log(result);
});

```