# stream-total

total for stream json objects or array,iterator.
support AMD or node.

## example


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
  ).stream()
).on('data', (doc)->
#console.log doc
).once 'end', (result) ->
  console.log result
  console.log 'sum age:',total.select(result,'sum.ageSum')
  console.log total.select(result,'frequency')[0].values
```

result:

```javascrip
{ ageAvg: 32.303030303030305,
  count: 99,
  sum: { ageSum: 3198, valueSum: 500326 },
  ageMax: 69,
  minAge: 1,
  modeGrade: 'grade 2',
  modeAge: '31',
  avedev: 16.524640342822156,
  stdev_s: 19.70934438355788,
  stdev_p: 19.609549593545182,
  custom: 9.33262154439441e+155,
  product: 9.33262154439441e+155,
  trimmean: 31.62295081967213,
  frequency: 
   [ { name: 'age<10', bound: 10, freq: 15 },
     { name: '10<=age<18', bound: 18, freq: 12 },
     { name: '18<=age<24', bound: 24, freq: 8 },
     { name: '24<=age<45', bound: 45, freq: 33 },
     { name: '45<=age<60', bound: 60, freq: 18 },
     { name: 'age>=60', bound: 60, freq: 13 } ] }

```

## extend total function

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
### using example:

```javascript

generator(100)
.pipe(total({product:{$custom:'age'}}).stream())
.once('end',function(result){
    console.log(result);
});

```

## using readArray example:

```javascript
var onPost = onProgress = function(doc){
    console.log(doc);
};

result = total({product:{$custom:'age'}}).readArray([{age:15,id:'ba'}],onPost,onProgress);

console.log(result);
```

## using readIterator example:

```javascript

var onPost = onProgress = function(doc){
    console.log(doc);
};

var data=[{age:15,id:'ba'}];

iterator ={
    hasNext:function(){return data.length>0;},
    next:function(){return data.shift();}
}

result = total({product:{$custom:'age'}}).readIterator(iterator,onPost,onProgress);

console.log(result);
```