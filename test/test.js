// Generated by CoffeeScript 1.9.3
var Stream, generator, total;

Stream = require('stream');

total = require('../total');

generator = function(n) {
  var i, next, s;
  s = new Stream;
  i = 1;
  next = function() {
    s.emit('data', {
      name: 'name ' + i,
      value: Math.floor((i + Math.random()) * 100),
      age: Math.floor(i * 100 * Math.random() % 70),
      n_value: i,
      grade: {
        name: 'grade ' + (i % 6 + 1)
      }
    });
    i++;
    if (i === n) {
      s.emit('end');
    } else {
      process.nextTick(next);
    }
  };
  s.readable = true;
  process.nextTick(next);
  return s;
};

total.use('$custom', function(doc, count) {
  var ret;
  ret = total.sum(total.getValues(doc, this.args, count));
  if (count === 1) {
    return this.prevalue = ret;
  } else {
    return this.prevalue *= ret;
  }
});

generator(100).pipe(total({
  ageAvg: {
    $avg: ['age']
  },
  count: {
    $count: '*'
  },
  sum: {
    ageSum: {
      $sum: 'age'
    },
    valueSum: {
      $sum: 'value'
    }
  },
  ageMax: {
    $max: ['age']
  },
  minAge: {
    $min: ['age']
  },
  modeGrade: {
    $mode: 'grade.name'
  },
  modeAge: {
    $mode: 'age'
  },
  avedev: {
    $avedev: 'age'
  },
  stdev_s: {
    $stdev_s: ['age']
  },
  stdev_p: {
    $stdev_p: 'age'
  },
  custom: {
    $custom: 'n_value'
  },
  product: {
    $product: 'n_value'
  },
  trimmean: {
    $trimmean: ['age', 0.4]
  },
  frequency: {
    $frequency: [
      'age', 18, 10, 24, function() {
        console.log(this);
        return 45;
      }, 60
    ]
  }
}).stream()).on('data', function(doc) {}).once('end', function(result) {
  console.log(result);
  console.log('sum age:', total.select(result, 'sum.ageSum'));
  return console.log(total.select(result, 'frequency')[0].values);
});

//# sourceMappingURL=test.js.map
