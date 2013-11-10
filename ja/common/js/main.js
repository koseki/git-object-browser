function routingConfig(steps) {
  return function($routeProvider) {
    $routeProvider = angular.extend($routeProvider, {

      // AngularJS doesn't support regular expressions in routes.
      // http://stackoverflow.com/questions/12685085/angularjs-route-how-to-match-star-as-a-path
      'whenPath': function(path, depth, route) {
        for (var i = 1; i <= depth; i++) {
          path += '/:path' + i;
          this.when(path, route);
        }
        return this;
      }
    });
    if (steps.length > 0) {
      $routeProvider.
        whenPath('/:basedir/.git', 10, {controller:GitCtrl, templateUrl:'common/templates/git.html'}).
        otherwise({redirectTo:'/' + steps[0].name + '/.git/'});
    } else {
      $routeProvider.
        whenPath('/.git', 10, {controller:GitCtrl, templateUrl:'common/templates/git.html'}).
        otherwise({redirectTo:'/.git/'});
    }
  }
}

angular.module('GitObjectBrowser', ['ngResource'])
  .config(routingConfig(config.steps))

  .directive('scrollBottom', function() {
    return function(scope, elm, attr) {
      var rawDomElement = elm[0];
      angular.element(window).unbind('scroll');
      angular.element(window).bind('scroll', function() {
        if (! scope.scrollBottomEnabled) return;

        var rectObject = rawDomElement.getBoundingClientRect();
        if (rectObject.bottom - window.innerHeight < 50) {
          scope.$apply(attr.scrollBottom);
        }
      });
    };
  })

  .directive('entryIcon', function($parse) {
    return function(scope, element, attrs) {
      var icons = {
        'directory': 'icon-folder-open',
        'ref': 'icon-map-marker',
        'reflog': 'icon-file',
        'info_refs': 'icon-map-marker',
        'packed_refs': 'icon-map-marker',
        'index': 'icon-list',
        'file': 'icon-file',
        'object': 'icon-comment',
        'blob': 'icon-file',
        'tree': 'icon-folder-open',
        'commit': 'icon-ok',
        'tag': 'icon-tag',
        'ofs_delta': 'icon-arrow-up',
        'ref_delta': 'icon-arrow-down'
      };

      var entryType = ($parse(attrs.entryIcon))(scope);
      element.addClass(icons[entryType]);
    }
  })

  .directive('modeIcon', function($parse) {
    return function(scope, element, attrs) {
      var mode = ($parse(attrs.modeIcon))(scope);
      var iconClass;
      if (120000 <= mode) {
        iconClass = 'icon-share-alt';
      } else if (100000 <= mode) {
        iconClass = 'icon-file';
      } else {
        iconClass = 'icon-folder-open';
      }
      element.addClass(iconClass);
    }
  })

  .directive('refHref', function($parse, $rootScope) {
    return function(scope, element, attrs) {
      var entry = ($parse(attrs.refHref))(scope);
      var href = "";
      var sha1 = null;

      if (typeof(entry) == 'string') {
        sha1 = entry;
      } else if (entry && entry.sha1) {
        sha1 = entry.sha1;
      }

      if (sha1 !== null) {
        href = '#' + $rootScope.basedir + '/.git/objects/' + sha1.substr(0, 2) + '/' + sha1.substr(2);
      } else if (entry && entry.ref) {
        href = '#' + $rootScope.basedir + '/.git/' + entry.ref;
      }

      element.attr('href', href);
    }
  })

  .filter('unixtime', function($filter) {
    return function(input, format) {
      return ($filter('date'))(input * 1000, format);
    }
  });

function GitCtrl($scope, $location, $routeParams, $rootScope, $resource, $http) {
  if (! $rootScope.diffCache) $rootScope.diffCache = {};
  if (! $rootScope.noteCache) $rootScope.noteCache = {};
  $scope.steps = config.steps;
  $scope.stepLinkEnabled = (config.steps.length > 0);

  $scope.stepPrev = function() { $scope.$emit('stepPrev', {}); };
  $scope.stepNext = function() { $scope.$emit('stepNext', {}); };

  // reset scrollBottom event handler
  angular.element(window).unbind('scroll');

  var objectTable = function(entries) {
    var rows = [];
    var hash = {};

    angular.forEach(entries, function(entry) {
      hash[entry.basename] = entry;
    })

    var hex = ['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'];
    for (var i = 0; i < 16; i++) {
      var cols = [];
      for (var j = 0; j < 16; j++) {
        if (hash[hex[i] + hex[j]]) {
          cols[j] = hash[hex[i] + hex[j]];
        } else {
          cols[j] = {'basename': hex[i] + hex[j], 'type': 'empty'};
        }
      }
      rows[i] = cols;
    }
    return rows;
  }

  var findIndexEntry = function(sha1) {
    var entries = $scope.object.entries;
    var entry = null;
    angular.forEach(entries, function(value) {
      if (value.sha1 == sha1) {
        entry = value;
        return;
      }
    });
    return entry;
  };

  var indexEntryKeys = function(version) {
    var keys = [
      'ctime',
      'cnano',
      'mtime',
      'mnano',
      'dev',
      'ino',
      'object_type',
      'unix_permission',
      'uid',
      'gid',
      'size',
      'sha1',
      'assume_valid_flag',
      'extended_flag',
      'stage',
      'name_length'
    ]
    if (version > 2) {
      keys = keys.concat([
        'skip_worktree',
        'intent_to_add',
      ]);
    }
    keys.push('path')

    return keys;
  };

  var splitPath = function() {
    var pathTokens = $scope.path.split('/');
    var token;
    var fullpath = ""
    for (var i = 0; i < pathTokens.length; i++) {
      token = {}
      token.label = pathTokens[i];
      if (pathTokens.length == i + 1) {
        fullpath += token.label;
        token.last = true;
      } else {
        fullpath += token.label + '/';
        token.last = false;
      }
      token.path = fullpath;
      pathTokens[i] = token;
    }
    return pathTokens;
  };

  var resourceLoaded = function(json) {
    $scope.workingdir = json.workingdir;
    $scope.root = json.root;
    $scope.gitPath = json.path;
    if (json.path == "") {
      $scope.path = ".git";
    } else {
      $scope.path = ".git/" + json.path;
    }
    $scope.pathTokens = splitPath();

    $scope.object = json.object;
    $scope.keys = indexEntryKeys($scope.object.version);
    var template;
    if (json.path == "objects") {
      template = "objects";
      $scope.objectTable = objectTable($scope.object.entries);
      loadDiffData();
    } else if (json.type == "index" && $routeParams.sha1) {
      template = "index_entry";
      $scope.entry = findIndexEntry($routeParams.sha1);
    } else if (json.type == "packed_refs" && $routeParams.ref) {
      template = json.type;
      var entries = [];
      angular.forEach($scope.object.entries, function(entry) {
        if (entry.ref == $routeParams.ref) {
          entries.push(entry);
          $scope.limited = true;
        }
      });
      $scope.object.entries = entries;
    } else if (json.type == "packed_object") {
      template = json.type;
      $scope.unpacked = json.unpacked;
    } else if (json.type == "directory") {
      template = json.type;
      loadDiffData();
    } else if (json.type == "pack_index") {
      var last_page = Math.ceil(json.entry_count / json.per_page);
      $scope.scrollBottomEnabled = (json.page < last_page);
      template = json.type;
    } else {
      template = json.type;
    }

    $scope.template = 'common/templates/' + template + '.html';
  };

  var loadNote = function() {
    if (! config.loadNote) return;
    var basedir, url;
    if ($rootScope.basedir) {
      basedir = $rootScope.basedir;
      url = 'notes' + basedir + '.html';
    } else {
      basedir = '';
      url = 'note.html';
    }
    if ($rootScope.noteCache[basedir] !== undefined) {
      $rootScope.note = $rootScope.noteCache[basedir];
      return;
    }
    $http.get(url)
      .success(function(data) {
        $rootScope.noteCache[basedir] = data;
        $rootScope.note = data;
      }).error(function() {
        $rootScope.noteCache[basedir] = '';
        $rootScope.note = null;
      });
  };

  var loadDiffData = function() {
    if (! config.loadDiff) return;
    var stepPath = $rootScope.basedir;
    if (! stepPath) return;

    $scope.diff = {}
    var base = '.git/';
    if ($scope.object.path !== '') {
      base = base + $scope.object.path + '/';
    }
    angular.forEach($scope.object.entries, function(entry) {
      $scope.diff[base + entry.basename] = null;
    });

    var cache = $rootScope.diffCache[stepPath];
    if (cache) {
      diffDataLoaded(cache);
      return
    }
    $http.get('json' + stepPath + '/_diff.json').success(function(diffData) {
      $rootScope.diffCache[stepPath] = diffData;
      diffDataLoaded(diffData);
    }).error(function() {
      $rootScope.diffCache[stepPath] = [];
    });
  };

  var diffDataLoaded = function(data) {
    var newDiffData = {}
    angular.forEach($scope.diff, function(value, key) {
      newDiffData[key] = isDiffEntry(data, key);
    });
    $scope.diff = newDiffData;
  }

  var isDiffEntry = function(data, key) {
    for(var i = 0; i < data.length; i++) {
      if (('.git/' + data[i]).indexOf(key) === 0) {
        return '#fee';
      }
    }
    return null;
  }

  $scope.resourceError = function(path) {
    return function(data, status, headers, config) {
      if (status == 404) {
        resourceNotFound(path);
      } else {
        $scope.status = status;
        $scope.path = path;
        $scope.template = 'common/templates/error.html';
      }
    };
  };

  var packedObjectFinder = function(sha1) {
    var indexes = [];

    var find = function() {
      $http.get('json' + $rootScope.basedir + '/objects/pack.json')
        .success(startLoadPackDigest)
        .error(showNotFound);
    };

    var startLoadPackDigest = function(json) {
      angular.forEach(json.object.entries, function(entry) {
        if (entry.basename.match(/\.idx$/)) {
          indexes.push(entry);
        }
      });
      loadPackDigest();
    };

    var loadPackDigest = function() {
      if (indexes.length == 0) {
        showNotFound();
        return;
      }
      var entry = indexes.shift();
      $http.get('json' + $rootScope.basedir + '/objects/pack/' + entry.basename + '.json')
        .success(findPackObject)
        .error(showNotFound);
    };

    var findPackObject = function(json) {
      var i = 0;
      angular.forEach(json.object.entries, function(digestSha1) {
        if (sha1 <= digestSha1) {
          return;
        }
        i++;
      });

      if (i == 0) {
        loadPackDigest();
        return;
      }

      $http.get('json' + $rootScope.basedir + '/' + json.path + '/sha1/' + i + '.json')
        .success(loadPagedIndex)
        .error(showNotFound);
    };

    var loadPagedIndex = function(json) {
      var found = false;
      angular.forEach(json.object.entries, function(entry) {
        if (entry.sha1 == sha1) {
          var path = json.path.replace(/.idx$/, '.pack');
          found = true;
          $routeParams.offset = entry.offset;
          loadJson([$rootScope.basedir, path]);
        }
      });
      if (! found) loadPackDigest();
    }

    find();
  };

  var resourceNotFound = function(path) {
    $scope.path = path;
    if (path.match(/^json\/[^\/]+\/objects\/([0-9a-f]{2})\/([0-9a-f]{38})\.json$/)) {
      packedObjectFinder(RegExp.$1 + RegExp.$2);
    } else if (path.match(/^json\/[^\/]+\/(refs\/.+)\.json$/)) {
      $routeParams.ref = RegExp.$1;
      loadJson([$rootScope.basedir, 'packed-refs'])
    } else {
      $scope.template = 'common/templates/notfound.html';
    }
  };

  var showNotFound = function() {
    $scope.template = 'common/templates/notfound.html';
  }

  // ['',         '/.git/xxx'] or
  // ['/basedir', '/.git/xxx']
  var buildPath = function() {
    var path = '';
    var basedir = '';
    if ($routeParams['basedir'] !== undefined) {
      basedir = '/' + $routeParams['basedir'];
    }
    for (var i = 1; i <= 10; i++) {
      if ($routeParams['path' + i]) {
        if (i > 1) path += '/';
        path += $routeParams['path' + i];
      }
    }
    return [basedir, path];
  }

  var loadJson = function(path) {
    $rootScope.basedir = path[0];
    $scope.template = 'common/templates/loading.html';

    if (path[1].match(/^objects\/pack\/pack-[0-9a-f]{40}\.pack$/) && $routeParams.offset) {
      var offset = '0000' + $routeParams.offset;
      path = 'json' + path[0] + '/' + path[1]
        + '/' + offset.slice(-2)
        + '/' + offset.slice(-4, -2)
        + '/' + $routeParams.offset + '.json';
    } else if (path[1].match(/^objects\/pack\/pack-[0-9a-f]{40}\.idx$/)) {
      var order = $routeParams.order == 'offset' ? 'offset' : 'sha1';
      var page  = $routeParams.page || 1;
      path = 'json' + path[0] + '/' + path[1] + '/' + order + '/' + page + '.json';
    } else {
      if (path[1] == '') path[1] = '_git';
      path = 'json' + path[0] + '/' + path[1] + '.json';
    }
    $http.get(path).success(resourceLoaded).error($scope.resourceError(path));
  };

  loadJson(buildPath());
  loadNote();
}

function PackFileCtrl($scope, $location, $routeParams) {
  $scope.indexUrl = $scope.path.replace(/.pack$/, '.idx');
}

function PackIndexCtrl($scope, $location, $routeParams, $rootScope, $resource, $http) {

  $scope.packUrl = $scope.path.replace(/.idx$/, '.pack');
  $scope.lastPage = 1;
  $scope.scrollBottomEnabled = $scope.$parent.scrollBottomEnabled;

  var resourceLoaded = function(json) {
    $scope.object.entries = $scope.object.entries.concat(json.object.entries);
    var last_page = Math.ceil(json.entry_count / json.per_page);
    $scope.scrollBottomEnabled = (json.page < last_page);
    $scope.loading = false;
  }

  $scope.loadNextPage = function() {
    $scope.lastPage += 1;

    var order = $routeParams.order == 'offset' ? 'offset' : 'sha1';
    var path = 'json' + $rootScope.basedir + '/' + $scope.gitPath + '/' + order + '/' + $scope.lastPage + '.json';

    $http.get(path).success(resourceLoaded).error($scope.resourceError(path));
  };

  $scope.scrollBottom = function() {
    $scope.scrollBottomEnabled = false;
    $scope.loading = true;
    $scope.loadNextPage();
  }

}

function MenuCtrl($scope, $location, $routeParams, $rootScope) {
  $scope.steps = config.steps;

  $scope.stepPrev = function(goRoot = true) {
    var idx = getStepIndex();
    if (idx.index > 0) {
      if (goRoot) {
        $location.path('/' + $scope.steps[idx.index - 1].name + '/.git/');
      } else {
        $location.path('/' + $scope.steps[idx.index - 1].name + '/' + idx.file);
      }
    }
  }

  $scope.stepNext = function(goRoot = true) {
    var idx = getStepIndex();
    if (idx.index < $scope.steps.length - 1) {
      if (goRoot) {
        $location.path('/' + $scope.steps[idx.index + 1].name + '/.git/');
      } else {
        $location.path('/' + $scope.steps[idx.index + 1].name + '/' + idx.file);
      }
    }
  }

  $rootScope.$on('stepPrev', function() { $scope.stepPrev(false); });
  $rootScope.$on('stepNext', function() { $scope.stepNext(false); });

  var getStepIndex = function() {
    var path = $location.path();
    if (! path.match(/\/([^\/]+)\/(.+)/)) return null;

    var stepName = RegExp.$1;
    var file     = RegExp.$2;
    var obj = { stepName: stepName, file: file, index: 0 };

    for (var i = 0; i < $scope.steps.length; i++) {
      if (stepName == $scope.steps[i].name) {
        obj.index = i;
        return obj;
      }
    }
    return obj;
  }
}
