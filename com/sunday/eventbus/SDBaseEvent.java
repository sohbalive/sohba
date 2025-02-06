package com.sunday.eventbus;

public final class SDBaseEvent
{
	public Object data;
	public String tag;

	public SDBaseEvent()
	{
	}

	public SDBaseEvent(Object data, String tag)
	{
		this.data = data;
		this.tag = tag;
	}
}
