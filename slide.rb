# coding: utf-8

require 'fileutils'
require 'pp'

# format index 
# 配列から飛び出したときの対処
def f_i_with_array(i, array)
  if i < 0  
    return 0 
  elsif i >= array.size
    return array.size - 1
  end
  i
end

# 前のnスライドを取得
# 自分自身は出さない
def before_list(array, index, slide_size)
  a = array[f_i_with_array((index-slide_size), array)..index]
  if a.nil? or a.size == 0 
    return []
  end
  a.pop
  a
end

def after_list(array, index, slide_size)
  a = array[index..f_i_with_array((index+slide_size), array)]
  if a.nil? or a.size == 0 
    return []
  end
  a.shift 
  a
end

#
# afterとbeforeのlistのフォーマット
# input [["s1",3],["s1",2],["s2",1]], [], 3
# return [[["s1", 3], ["s1", 2], ["s2", 1]], [["", 1], ["", 2], ["", 3]]]
#
# [test]
# reuturn [3,2,1], [1,2,3] 
# pp before_after_format([["s1",3],["s1",2],["s2",1]], [], 3)
def before_after_format(before_list, after_list, slide_num)
  at = after_list 
  if after_list.size != slide_num
    # pathを空文字にする(後の混同をなくすため)
    at = before_list.reverse.map {|x| ["", x[1]]}
    for ai in 0..(after_list.size-1)
      at[ai] = after_list[ai]
    end
  end

  bt = before_list 
  if before_list.size != slide_num
    # pathを空文字にする(後の混同をなくすため)
    bt = after_list.map {|x| ["", x[1]]}
    for bi in 0..(before_list.size-1)
      bt[bi] = before_list.reverse[bi]
    end
    bt = bt.reverse
  end

  return [bt, at]
end

# listにsmoothをかける
# @param: i index番号
def smooth_weight(path_sim_arr_list, i, slide_num)
  # 前後スライド取得
  _before_list = before_list(path_sim_arr_list, i, slide_num)
  _after_list = after_list(path_sim_arr_list, i, slide_num)

  # 講演の端っこスライドの処理
  # 逆側の情報をコピー
  _before_list, _after_list = before_after_format(_before_list, _after_list, slide_num)

  # 重みの計算 (after)
  after_sum = 0.0
  _after_list.each_with_index do |(path, sim), i|
    after_sum += sim.to_f/(i+2)
  end

  # 重みの計算 (before)
  before_sum = 0.0
  _before_list.reverse.each_with_index do |(path, sim), i|
    before_sum += sim.to_f/(i+2)
  end

  path = path_sim_arr_list[i][0]
  score = after_sum + before_sum + path_sim_arr_list[i][1].to_f

  [path, score]
end

# 入力と出力のヘルパー
# 配列の配列を出力
def in_out(indir, outdir) 
  Dir.glob("#{indir}/*").each do |file|
    # sfを返す
    array_list = yield SimFile.new(file)

    # sortして、上位1000個を出す
    array_list = sort_with_score(array_list)[0..(1000-1)]

    s = ""
    array_list.each do |array|
      s += array.join(' ') + "\n"
    end

    if /\/(\d+.txt)$/ =~ file
      File.write("#{outdir}/#{$1}", s) 
    end
  end
end

def dd(ele)
  pp ele
  abort
end

def sort_with_score(shohin)
  sorted = shohin.sort do |a, b|
    # 降順
    -(a[1] <=> b[1])
  end
  sorted
end

class SimFile
  attr_reader :path

  def initialize(path)
    @path = path
    @list = nil
  end

  def lectures
    list = path_sim_arr_list
    res = []
    list.each do |path, sim|
      if /(\d+-\d+)_\d+\.txt/ =~ path
        res << $1
      end
    end
    res.uniq
  end

  def path_sim_arr_list
    if (!@list.nil?)
      return @list
    end

    path_sim_arr_list = []
    File.foreach(@path) do |line|
      path_sim_arr_list << line.split(' ') 
    end

    @list = sort_with_path(path_sim_arr_list)
    @list
  end

  # ある講演のデータを取得
  def path_sim_arr_list_with_lecture(lecture_id)
    path_sim_arr_list.select {|x| x[0].match(/#{lecture_id}/)}
  end

  private 
  def sort_with_path(shohin)
    sorted = shohin.sort do |a, b|
      a[0] <=> b[0] 
    end
    sorted
  end
end

# main
indir = "./query_likelihood/result_all"
outdir = "./query_likelihood/result"
slide_num = 5 

in_out(indir, outdir) do |sf|
  res = []

  sf.lectures.each do |lecture|
    list = []
    path_sim_arr_list = sf.path_sim_arr_list_with_lecture(lecture)

    for i in 0..(path_sim_arr_list.size-1) 
      list << smooth_weight(path_sim_arr_list, i, slide_num)
    end

    res += list
  end

  pp "[ok] #{sf.path}" 

  # return [[1,1],[1,1],...]
  res
end
