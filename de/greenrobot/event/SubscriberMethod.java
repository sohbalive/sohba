/*
 * Copyright (C) 2012 Markus Junginger, greenrobot (http://greenrobot.de)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package de.greenrobot.event;

import java.lang.reflect.Method;

final class SubscriberMethod
{
	final Method method;
	final ThreadMode threadMode;
	final Class<?> eventType;
	/** Used for efficient comparison */
	String methodString;

	SubscriberMethod(Method method, ThreadMode threadMode, Class<?> eventType)
	{
		this.method = method;
		this.threadMode = threadMode;
		this.eventType = eventType;
	}

	@Override
	public boolean equals(Object other)
	{
		if (other instanceof SubscriberMethod)
		{
			checkMethodString();
			SubscriberMethod otherSubscriberMethod = (SubscriberMethod) other;
			otherSubscriberMethod.checkMethodString();
			// Don't use method.equals because of
			// http://code.google.com/p/android/issues/detail?id=7811#c6
			return methodString.equals(otherSubscriberMethod.methodString);
		} else
		{
			return false;
		}
	}

	private synchronized void checkMethodString()
	{
		if (methodString == null)
		{
			// Method.toString has more overhead, just take relevant parts of
			// the method
			StringBuilder builder = new StringBuilder(64);
			builder.append(method.getDeclaringClass().getName());
			builder.append('#').append(method.getName());
			builder.append('(').append(eventType.getName());
			methodString = builder.toString();
		}
	}

	@Override
	public int hashCode()
	{
		return method.hashCode();
	}
}