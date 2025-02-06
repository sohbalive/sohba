package com.sunday.eventbus;

import de.greenrobot.event.EventBus;

/**
 * version:1.6
 * 
 * EventBus封装类
 * 
 * @date 2017-4-7 上午11:14:44
 */
public class SDEventManager
{
	/**
	 * 注册观察者
	 * 
	 * @param subscriber
	 */
	public static void register(Object subscriber)
	{
		EventBus.getDefault().register(subscriber);
	}

	/**
	 * 取消观察者
	 * 
	 * @param subscriber
	 */
	public static void unregister(Object subscriber)
	{
		EventBus.getDefault().unregister(subscriber);
	}

	/**
	 * 发送事件
	 * 
	 * @param event
	 */
	public static void post(Object event)
	{
		EventBus.getDefault().post(event);
	}

	/**
	 * 调用此方法发送事件，观察者必须实现SDEventObserver接口
	 * 
	 * @param tag
	 */
	public static void postTag(String tag)
	{
		post(new SDBaseEvent(null, tag));
	}

	/**
	 * 调用此方法发送事件，观察者必须实现SDEventObserver接口
	 * 
	 * @param tag
	 */
	public static void postTag(Object data, String tag)
	{
		post(new SDBaseEvent(data, tag));
	}
}
