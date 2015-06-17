// Generated by CoffeeScript 1.9.3
var Actuary, __exports, abs, avg, ceil, exec, exports, floor, floorPV, getValue, getValues, max, min, openPath, ops, parse, parseOp, pickLeadTail, pow, product, round, setPathValue, sort, sqrt, square, sum, total, use, wipeLeadTail;

__exports = function(template) {
  return new total(template);
};

total = (function() {
  function total(template1) {
    this.template = template1;
  }

  total.prototype.stream = function() {
    var actuary, s, through;
    through = require('through');
    actuary = new Actuary({
      template: this.template,
      onPost: function(doc) {
        return s.emit('end', doc);
      },
      onProgress: function(doc) {
        return s.emit('data', doc);
      }
    });
    s = through((function(doc) {
      return actuary.write(doc);
    }), function() {
      return actuary.end();
    });
    return s;
  };

  total.prototype.readArray = function(array, onPost, onProgress) {
    var actuary, i, item, len;
    actuary = new Actuary({
      template: this.template,
      onPost: onPost,
      onProgress: onProgress
    });
    for (i = 0, len = array.length; i < len; i++) {
      item = array[i];
      actuary.write(item);
    }
    actuary.end();
    return actuary.cache;
  };

  total.prototype.readIterator = function(iterator, onPost, onProgress) {
    var actuary;
    if ((iterator != null) && (typeof iterator.hasNext === "function" ? iterator.hasNext() : void 0) && 'function' === typeof iterator.next) {
      actuary = new Actuary({
        template: this.template,
        onPost: onPost,
        onProgress: onProgress
      });
      while (iterator.hasNext()) {
        actuary.write(iterator.next());
      }
      actuary.end();
      return actuary.cache;
    }
  };

  return total;

})();

__exports.Actuary = Actuary = (function() {
  function Actuary(option) {
    this.template = option.template, this.onPost = option.onPost, this.onProgress = option.onProgress;
    this.operators = parse(this.template);
    if (this.operators.length === 0) {
      throw new Error("You must set template!");
    }
    this.operators.count = 0;
    this.cache = {};
  }

  Actuary.prototype.write = function(doc) {
    this.operators.count++;
    exec(this.operators, doc);
    setPathValue(this.cache, this.operators);
    return this.onProgress(this.cache);
  };

  Actuary.prototype.end = function() {
    exec(this.operators);
    setPathValue(this.cache, this.operators);
    return this.onPost(this.cache);
  };

  return Actuary;

})();

exec = function(operators, doc) {
  var i, j, len, len1, op;
  if (doc) {
    for (i = 0, len = operators.length; i < len; i++) {
      op = operators[i];
      op.count = operators.count;
      op.value = op.exec(doc, operators.count);
    }
  } else {
    for (j = 0, len1 = operators.length; j < len1; j++) {
      op = operators[j];
      if (op.atEnd) {
        op.value = op.exec(null, operators.count);
      }
    }
  }
};

__exports.parse = parse = function(template, path) {
  var key, operator, operators, parent, value;
  parent = template;
  path = path || [];
  operators = [];
  for (key in parent) {
    value = parent[key];
    if ('$' === key[0] || 'function' === typeof value) {
      operator = {
        op: key,
        path: path.join('.'),
        args: value,
        custom: key[0] === '$' ? false : true,
        value: null,
        prevalue: null
      };
      parseOp(operator);
      operators.push(operator);
    } else {
      if ('object' === typeof value) {
        operators = operators.concat(parse(value, path.concat(key)));
      }
    }
  }
  return operators;
};

parseOp = function(op) {
  var key;
  if (op.custom) {
    op.exec = function(doc, count) {
      return this.prevalue = op.args.call(this, doc, count);
    };
  } else {
    op.args = !(op.args instanceof Array) ? [op.args] : op.args;
    for (key in ops) {
      if (key === op.op) {
        op.exec = ops[key];
        op.atEnd = ops.ends[key];
      }
    }
  }
};

__exports.sum = sum = function(array) {
  var i, len, ret, value;
  ret = 0;
  for (i = 0, len = array.length; i < len; i++) {
    value = array[i];
    ret += value || 0;
  }
  return ret;
};

__exports.avg = avg = function(array) {
  var count;
  count = array.length;
  if (count === 0) {
    return 0;
  } else {
    return sum(array) / count;
  }
};

__exports.product = product = function(array) {
  var i, len, p, prd;
  if (array.length === 0) {
    return 0;
  }
  prd = 1;
  for (i = 0, len = array.length; i < len; i++) {
    p = array[i];
    prd *= p;
  }
  return prd;
};

__exports.abs = abs = Math.abs;

__exports.pow = pow = Math.pow;

__exports.sqrt = sqrt = Math.sqrt;

__exports.floor = floor = Math.floor;

__exports.ceil = ceil = Math.ceil;

__exports.round = round = Math.round;

__exports.square = square = function(x) {
  return x * x;
};

__exports.max = max = function() {
  var arr, i, len, param;
  arr = [];
  for (i = 0, len = arguments.length; i < len; i++) {
    param = arguments[i];
    if (param instanceof Array) {
      arr = arr.concat(param);
    } else {
      arr.push(param);
    }
  }
  return Math.max.apply(null, arr);
};

__exports.min = min = function() {
  var arr, i, len, param;
  arr = [];
  for (i = 0, len = arguments.length; i < len; i++) {
    param = arguments[i];
    if (param instanceof Array) {
      arr = arr.concat(param);
    } else {
      arr.push(param);
    }
  }
  return Math.min.apply(null, arr);
};

__exports.floorPercentValue = __exports.floorPV = floorPV = function(count, percent, mod) {
  var d_count;
  d_count = floor(count * percent);
  return d_count -= d_count % (mod || 2);
};

__exports.sort = sort = function(array) {
  return array.sort(function(a, b) {
    if (a > b) {
      return 1;
    } else if (a < b) {
      return -1;
    } else {
      return 0;
    }
  });
};

__exports.wipeLeadTail = wipeLeadTail = function(array, percent) {
  var d_count;
  if ((0 < percent && percent < 1)) {
    d_count = (floorPV(array.length, percent)) / 2;
    return array.slice(d_count, +((-1) * (d_count + 1)) + 1 || 9e9);
  }
};

__exports.pickLeadTail = pickLeadTail = function(array, percent) {
  var d_count;
  if ((0 < percent && percent < 1)) {
    d_count = (floorPV(array.length, percent)) / 2;
    return array.slice(0, +(d_count - 1) + 1 || 9e9).concat(array.slice(d_count * -1));
  }
};

__exports.getValues = getValues = function(doc, args, count) {
  var i, key, len, results;
  results = [];
  for (i = 0, len = args.length; i < len; i++) {
    key = args[i];
    switch (typeof key) {
      case 'function':
        results.push(key(doc, count));
        break;
      case 'string':
        results.push(getValue(doc, key));
        break;
      default:
        results.push(key);
    }
  }
  return results;
};

__exports.select = getValue = function(doc, path) {
  var get, ref;
  if (arguments.length === 1) {
    ref = [doc, path], path = ref[0], doc = ref[1];
  }
  path = path.split('.');
  get = function(obj) {
    var key, lpath, ret;
    lpath = path.slice(0);
    ret = obj;
    while (key = lpath.shift()) {
      if (ret[key]) {
        ret = ret[key];
      } else {
        ret = null;
        break;
      }
    }
    return ret;
  };
  if (doc) {
    return get(doc);
  } else {
    return get;
  }
};

__exports.openPath = openPath = function(obj, path) {
  var paths, ret;
  paths = 'string' === typeof path ? path.split('.') : path;
  ret = obj;
  while (path = paths.shift()) {
    ret = obj[path];
    obj = ret = obj[path] = ret && 'object' === typeof ret ? ret : {};
  }
  return ret;
};

setPathValue = function(obj, operators) {
  var field, i, len, op, path;
  for (i = 0, len = operators.length; i < len; i++) {
    op = operators[i];
    path = op.path.split('.');
    if (op.custom) {
      path.push(op.op);
    }
    field = path.pop();
    openPath(obj, path)[field] = op.value;
  }
};

ops = {
  ends: {}
};

__exports.use = use = function(method, totalfn, atEnd) {
  ops[method] = 'function' === typeof totalfn ? totalfn : function() {};
  if (atEnd) {
    ops.ends[method] = ops[method] !== null;
  }
};

use('$sum', function(doc, count) {
  this.prevalue = this.prevalue || 0;
  return this.prevalue += sum(getValues(doc, this.args, count));
});

use('$avg', function(doc, count) {
  this.prevalue = this.prevalue || 1;
  this.prevalue = sum([this.prevalue * (count - 1), avg(getValues(doc, this.args, count))]);
  return this.prevalue /= count;
});

use('$count', function(doc, count) {
  return this.prevalue = count;
});

use('$max', function(doc, count) {
  var args;
  args = getValues(doc, this.args, count);
  args.push(this.prevalue || args[0]);
  return this.prevalue = max(args);
});

use('$min', function(doc, count) {
  var args;
  args = getValues(doc, this.args, count);
  args.push(this.prevalue || args[0]);
  return this.prevalue = min(args);
});

use('$product', function(doc, count) {
  var tmp;
  tmp = product(getValues(doc, this.args, count));
  if (count === 1) {
    return this.prevalue = tmp;
  } else {
    return this.prevalue *= tmp;
  }
});

use('$stdev_s', (function(doc, count) {
  var d_avg, d_values, value;
  if (doc) {
    this.values = (this.values || []).concat(getValues(doc, this.args, count));
    d_avg = avg(this.values);
    d_values = (function() {
      var i, len, ref, results;
      ref = this.values;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        value = ref[i];
        results.push(square(value - d_avg));
      }
      return results;
    }).call(this);
    this.prevalue = d_values.length <= 1 ? 0 : sqrt(sum(d_values) / (d_values.length - 1));
  } else {
    delete this.values;
  }
  return this.prevalue;
}), true);

use('$stdev_p', (function(doc, count) {
  var d_avg, d_values, value;
  if (doc) {
    this.values = (this.values || []).concat(getValues(doc, this.args, count));
    d_avg = avg(this.values);
    d_values = (function() {
      var i, len, ref, results;
      ref = this.values;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        value = ref[i];
        results.push(square(value - d_avg));
      }
      return results;
    }).call(this);
    this.prevalue = d_values.length ? sqrt(avg(d_values)) : 0;
  } else {
    delete this.values;
  }
  return this.prevalue;
}), true);

use('$avedev', (function(doc, count) {
  var d_avg, value;
  if (doc) {
    this.values = (this.values || []).concat(getValues(doc, this.args, count));
    d_avg = avg(this.values);
    this.prevalue = avg((function() {
      var i, len, ref, results;
      ref = this.values;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        value = ref[i];
        results.push(abs(value - d_avg));
      }
      return results;
    }).call(this));
  } else {
    delete this.values;
  }
  return this.prevalue;
}), true);

use('$mode', function(doc, count) {
  var i, key, len, ref, ret, t_count, value, values;
  this.prevalue = this.prevalue || {};
  values = getValues(doc, this.args, count);
  for (i = 0, len = values.length; i < len; i++) {
    value = values[i];
    this.prevalue[value] = this.prevalue[value] || 0;
    this.prevalue[value]++;
  }
  t_count = 0;
  ret = null;
  ref = this.prevalue;
  for (key in ref) {
    value = ref[key];
    if (value > t_count) {
      t_count = value;
      ret = key;
    }
  }
  return ret;
});

use('devsq', (function(doc, count) {
  var d_avg, value;
  if (doc) {
    this.values = (this.values || []).concat(getValues(doc, this.args, count));
    d_avg = avg(this.values);
    this.prevalue = sum((function() {
      var i, len, ref, results;
      ref = this.values;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        value = ref[i];
        results.push(square(value - d_avg));
      }
      return results;
    }).call(this));
  } else {
    delete this.values;
  }
  return this.prevalue;
}), true);

use('$trimmean', (function(doc, count) {
  var args;
  args = this.args[0] instanceof Array ? this.args[0] : this.args.slice(0, 1);
  this.percent = this.args[1] || 0.1;
  this.percent = 'function' === typeof this.percent ? this.percent() : this.percent;
  this.exec = function(doc, count) {
    if (doc) {
      this.values = (this.values || []).concat(getValues(doc, args, count));
      this.prevalue = avg(wipeLeadTail(sort(this.values), this.percent));
    } else {
      delete this.values;
    }
    return this.prevalue;
  };
  return this.exec(doc, count);
}), true);

use('$frequency', (function(doc, count) {
  var fields, i, j, last, len, len1, ref, ref1, v, val, zone;
  fields = this.args[0] instanceof Array ? this.args[0] : this.args.slice(0, 1);
  zone = [];
  ref = this.args.slice(1);
  for (i = 0, len = ref.length; i < len; i++) {
    v = ref[i];
    zone = zone.concat('function' === typeof v ? v.call(this) : v);
  }
  zone = sort(zone);
  this.prevalue = [];
  val = zone[0];
  this.prevalue.push({
    name: (fields.join(',')) + "<" + val,
    bound: val,
    freq: 0
  });
  ref1 = zone.slice(1);
  for (j = 0, len1 = ref1.length; j < len1; j++) {
    v = ref1[j];
    this.prevalue.push({
      name: val + "<=" + (fields.join(',')) + "<" + v,
      bound: val = v,
      freq: 0
    });
  }
  this.prevalue.push(last = {
    name: (fields.join(',')) + ">=" + val,
    bound: val,
    freq: 0
  });
  this.exec = function(doc, count) {
    var k, l, len2, len3, obj, ref2, value, values;
    if (doc) {
      values = getValues(doc, fields, count) || [];
      for (k = 0, len2 = values.length; k < len2; k++) {
        value = values[k];
        if (value >= last.bound) {
          last.freq++;
        } else {
          ref2 = this.prevalue;
          for (l = 0, len3 = ref2.length; l < len3; l++) {
            obj = ref2[l];
            if (obj.bound > value) {
              obj.freq++;
              break;
            }
          }
        }
      }
    }
    return this.prevalue;
  };
  return this.exec(doc, count);
}));

if ((typeof exports !== "undefined" && exports !== null) && (typeof module !== "undefined" && module !== null) && (module.exports != null)) {
  exports = module.exports = __exports;
}

if ('function' === typeof define && (define.amd != null)) {
  define(null, [], function() {
    return __exports;
  });
}

//# sourceMappingURL=total.js.map
